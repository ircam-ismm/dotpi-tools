import fs from 'node:fs/promises';
import path from 'node:path';

import { $ } from 'execa';

import * as echo from '@dotpi/javascript/echo.js';
import { configurationGet } from './configuration.js';
import { skip } from 'node:test';

export async function uninstall(modules) {
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
     } = await configurationGet() );
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

      echo.info(`Getting '${moduleToUninstall}' definition`);
      output = await $`npm view --json -- ${moduleToUninstall}`;
      const moduleDefinition = JSON.parse(output.stdout);
      const { name: moduleName } = moduleDefinition;

      // uninstall actually installed module
      moduleToUninstall = moduleName;

      echo.info(`Uninstalling module '${moduleToUninstall}' in '${dotpiModulesDestination}'`);

      cwd = path.join(dotpiModulesDestination, 'node_modules', moduleName);

      // throw error if module is not installed, caught to continue with next module
      await fs.access(cwd);

      output = await $({
        cwd,
      })`npm --prefix ${cwd}
           run --json
        `;
      const uninstallScript = JSON.parse(output.stdout).preuninstall;

      if (uninstallScript) {
        // npm does not automatically run preuninstall script
        echo.info(`Running uninstall script for ${moduleToUninstall}`);
        await $({
          cwd,
          env: { FORCE_COLOR: 'true' }, // do not remove colors
          verbose: 'full', // print stdout and stderr
        })`npm --prefix ${cwd}
             run preuninstall
          `;
      }

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
