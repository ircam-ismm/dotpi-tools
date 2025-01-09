import fs from 'node:fs/promises';
import path from 'node:path';

import { $ } from 'execa';
import { globby } from 'globby';

import * as echo from '@dotpi/javascript/echo.js';
import { configurationGet } from './configuration.js';

async function uninstallScriptRun(module) {
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
      echo.info(`Running uninstall script for ${module}`);
      await $({
        cwd,
        env: { FORCE_COLOR: 'true' }, // do not remove colors
        verbose: 'full', // print stdout and stderr
      })`npm --prefix ${cwd}
             run preuninstall
          `;
    }
    console.log(output.all);

    return output;
  } catch (error) {
    echo.error(`Failed to run uninstall script for ${module}: ${error.message}`);
    throw error;
  }
}

export async function uninstall(modules = []) {
  if (typeof modules === 'string') {
    modules = [modules];
  }

  if (process.getuid() !== 0) {
    echo.error('This script must be run as root');
    process.exit(1);
  }

  let dotpiModulesDestination;
  let dotpiModulesConfiguration;
  try {
    ({
      modulesPath: dotpiModulesDestination,
      modulesConfiguration: dotpiModulesConfiguration,
    } = await configurationGet());
  } catch (error) {
    process.exit(1);
  }

  // no parallelisation to uninstall modules
  let moduleToUninstall;
  for (const module of modules) {
    try {
      const moduleRegistered = dotpiModulesConfiguration.moduleSource[module];
      if (moduleRegistered) {
        echo.info(`Module '${module}' is registered as '${moduleRegistered}'`);
        moduleToUninstall = moduleRegistered;
      } else {
        moduleToUninstall = module;
      }

      let output;
      let cwd;

      console.log(`Getting '${moduleToUninstall}' definition`);
      output = await $`npm view --json -- ${moduleToUninstall}`;
      const moduleDefinition = JSON.parse(output.stdout);
      const { name: moduleName } = moduleDefinition;

      // uninstall actually installed module
      moduleToUninstall = moduleName;

      echo.info(`Uninstalling module '${moduleToUninstall}' in '${dotpiModulesDestination}'`);

      cwd = path.join(dotpiModulesDestination, 'node_modules', moduleName);

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
          await uninstallScriptRun(dependency);
        } catch (error) {
          // continue with other dependencies
        }
      }

      output = await uninstallScriptRun(cwd);

      echo.info(`Uninstalling ${moduleToUninstall}`);
      cwd = dotpiModulesDestination;
      output = await $({
        cwd,
        env: { FORCE_COLOR: 'true' }, // do not remove colors
        verbose: 'full', // print stdout and stderr
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
