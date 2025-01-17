import fs from 'node:fs/promises';
import path from 'node:path';

import { $ } from 'execa';
import { globby } from 'globby';

import * as echo from '@dotpi/javascript/echo.js';

import { dotpiConfigurationGet } from './configuration.js';
import { definitionGet } from './definition.js';

export async function uninstallCommandDefine({program}) {
  program
    .command('uninstall [modules...]')
    .summary('uninstall a list of modules')
    .description('Uninstall a list of modules separated by space.')
    .option('-r, --dotpi-root <path>', 'dotpi root path, to initialise environment')
    .option('-p, --prefix <path>', 'install modules in this directory')
    .option('-v, --verbose [full]', 'print verbose output [full]')
    .action((modules, options, command) => uninstall(modules, { ...options, command }));
  ;
  return program;
}

async function uninstallScriptRun(module, {
  verbose = 'short',
} = {}) {
  try {

    const cwd = module;
    const output = await $({
      cwd,
    })`npm --prefix ${cwd}
           run --json
        `;
    const uninstallScript = JSON.parse(output.stdout).preuninstall;

    if (uninstallScript) {
      // npm does not automatically run preuninstall script

      if(verbose !== 'none') {
        echo.info(`Running uninstall script for ${module}`);
      }
      await $({
        cwd,
        env: { FORCE_COLOR: 'true' }, // do not remove colors
        verbose: (verbose === 'full' ? 'full' : 'none'),
      })`npm --prefix ${cwd}
             run preuninstall
          `;
    }

    return output;
  } catch (error) {
    echo.error(`Failed to run uninstall script for ${module}: ${error.message}`);
    throw error;
  }
}

export async function uninstall(modules = [], {
  dotpiRoot,
  prefix,
  verbose = 'short',
} = {}) {
  if (typeof modules === 'string') {
    modules = [modules];
  }

  switch (verbose) {
    case '0':
    case 'false':
    case false:
      verbose = 'none';
      break;

    case '1':
    case 'true':
    case true:
      verbose = 'short';
      break;

    case '2':
      verbose = 'full';
      break;
  }

  let dotpiModulesDestination;
  let dotpiModulesConfiguration;
  try {
    ({
      modulesPath: dotpiModulesDestination,
      modulesConfiguration: dotpiModulesConfiguration,
    } = await dotpiConfigurationGet({ dotpiRoot, prefix }));
  } catch (error) {
    echo.error(`Failed to get dotpi configuration: ${error.message}`);
    process.exit(1);
  }

  // no parallelisation to uninstall modules
  let moduleToUninstall;
  for (const module of modules) {
    try {
      const moduleRegistered = dotpiModulesConfiguration.moduleSource[module];
      if (moduleRegistered) {
        if(verbose !== 'none') {
          echo.info(`Module '${module}' is registered as '${moduleRegistered}'`);
        }
        moduleToUninstall = moduleRegistered;
      } else {
        moduleToUninstall = module;
      }

      let output;
      let cwd;

      if(verbose === 'full') {
        console.log(`Getting '${moduleToUninstall}' definition`);
      }
      const moduleDefinition = await definitionGet(moduleToUninstall);
      const { name: moduleName } = moduleDefinition;

      // uninstall actually installed module
      moduleToUninstall = moduleName;

      if(verbose !== 'none') {
        echo.info(`Uninstalling module '${moduleToUninstall}' in '${dotpiModulesDestination}'`);
      }

      cwd = path.resolve(dotpiModulesDestination, 'node_modules', moduleName);

      // throw error if module is not installed, caught to continue with next module
      await fs.access(cwd);

      // First, uninstall dependencies manually,
      // as npm doest not execute {pre,post}uninstall scripts since version 7

      const dependencies = await globby(
        // globby needs a posix path
        `${path.posix.resolve(cwd)}/**/node_modules/*`
      );
      for(const dependency of dependencies) {
        try {
          await uninstallScriptRun(dependency, { verbose });
        } catch (error) {
          // continue with other dependencies
        }
      }

      output = await uninstallScriptRun(cwd, { verbose });

      if(verbose !== 'none') {
        echo.info(`Uninstalling ${moduleToUninstall}`);
      }

      cwd = dotpiModulesDestination;
      output = await $({
        cwd,
        env: { FORCE_COLOR: 'true' }, // do not remove colors
        verbose: (verbose === 'full' ? 'full' : 'none'),
      })`
        npm --prefix ${cwd}
          uninstall
          --save
          --
          ${moduleName}
        `;

    } catch (error) {
      if (error.code === 'ENOENT') {
        echo.warning(`Module ${moduleToUninstall} is not installed`);
        continue;
      }

      // give up for other errors
      echo.error(`Failed to uninstall ${moduleToUninstall}: ${error.message}`);
      process.exit(1);
    }

  } // for (const module of modules)
}
