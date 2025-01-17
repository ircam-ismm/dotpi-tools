import fs from 'node:fs/promises';
import path from 'node:path';

import { $ } from 'execa';

import { symlink } from '@dotpi/javascript/filesystem.js';
import * as echo from '@dotpi/javascript/echo.js';

import { dotpiConfigurationGet } from './configuration.js';
import { definitionGet } from './definition.js';

export function installCommandDefine({program}) {
  program
    .command('install [modules...]')
    .summary('install a list of modules')
    .description('Install a list of modules separated by space.')
    .option('-r, --dotpi-root <path>', 'dotpi root path, to initialise environment')
    .option('-p, --prefix <path>', 'install modules in this directory')
    .option('-v, --verbose [full]', 'print verbose output [full]')
    .action((modules, options, command) => install(modules, { ...options, command }));
  ;

  return program;
}

export async function install(modules = [], {
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
     } = await dotpiConfigurationGet({dotpiRoot, prefix}) );
  } catch (error) {
    echo.error(`Failed to get dotpi configuration: ${error.message}`);
    process.exit(1);
  }

  // no parallelisation to install modules
  let moduleToInstall;
  for (const module of modules) {
    try {
      const moduleRegistered = dotpiModulesConfiguration.moduleSource[module];
      if (moduleRegistered) {
        echo.info(`Module '${module}' is registered as '${moduleRegistered}'`);
        moduleToInstall = moduleRegistered;
      } else {
        moduleToInstall = module;
      }

      let output;
      let cwd;

      if(verbose === 'full') {
        console.log(`Getting '${moduleToInstall}' definition`);
      }
      const moduleDefinition = await definitionGet(moduleToInstall);
      const { name: moduleName } = moduleDefinition;

      // 2-steps install as npm errors when installing from git
      // npm error git dep preparation failed

      if(verbose !== 'none') {
        echo.info(`Installing module '${moduleToInstall}' in '${dotpiModulesDestination}'`);
      }
      cwd = dotpiModulesDestination;
      output = await $({
        cwd,
        env: { FORCE_COLOR: 'true' }, // do not remove colors
        verbose: (verbose === 'full' ? 'full' : 'none'),
        // minimal install in the modules directory
      })`
        npm --prefix ${cwd}
          install --no-fund
          --install-strategy nested
          --omit dev
          --save
          --ignore-scripts
          --
          ${moduleToInstall}
        `;

      await symlink(
        path.join('.', 'node_modules'),
        path.join(dotpiModulesDestination, 'dotpi_modules')
      );

      if(verbose === 'full') {
        echo.info(`Installing ${moduleToInstall} dependencies`)
      }
      cwd = path.resolve(dotpiModulesDestination, 'node_modules', moduleName);

      // perform a clean install
      await fs.rm(path.resolve(cwd, 'node_modules'), {
        recursive: true,
        force: true,
      });

      output = await $({
        cwd,
        env: { FORCE_COLOR: 'true' }, // do not remove colors
        verbose: (verbose === 'full' ? 'full' : 'none'),
        // complete install within the module itself
        // be sure to install links for relative dependencies also
        // run postinstall script
      })`
        npm --prefix ${cwd}
          install --no-fund
          --omit dev
          --install-links
        `;

    } catch (error) {
      echo.error(`Failed to install ${moduleToInstall}: ${error.message}`);
      process.exit(1);
    }

  }
}
