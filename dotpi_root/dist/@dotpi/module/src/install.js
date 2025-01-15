import fs from 'node:fs/promises';
import path from 'node:path';

import { $ } from 'execa';

import { symlink } from '@dotpi/javascript/filesystem.js';
import * as echo from '@dotpi/javascript/echo.js';
import { dotpiConfigurationGet } from './configuration.js';

export async function install(modules = [], {
  dotpiRoot,
  prefix,
} = {}) {
  if (typeof modules === 'string') {
    modules = [modules];
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

      console.log(`Getting '${moduleToInstall}' definition`);
      output = await $`npm view --json -- ${moduleToInstall}`;
      const moduleDefinition = JSON.parse(output.stdout);
      const { name: moduleName } = moduleDefinition;

      echo.info(`Installing module '${moduleToInstall}' in '${dotpiModulesDestination}'`);
      cwd = dotpiModulesDestination;
      output = await $({
        cwd,
        env: { FORCE_COLOR: 'true' }, // do not remove colors
        verbose: 'full', // print stdout and stderr
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

      echo.info(`Installing ${moduleToInstall} dependencies`)
      cwd = path.join(dotpiModulesDestination, 'node_modules', moduleName);

      // perform a clean install
      await fs.rm(path.join(cwd, 'node_modules'), {
        recursive: true,
        force: true,
      });

      output = await $({
        cwd,
        env: { FORCE_COLOR: 'true' }, // do not remove colors
        verbose: 'full', // print stdout and stderr
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
