import fs from 'node:fs/promises';
import path from 'node:path';

import { $ } from 'execa';

import * as echo from '@dotpi/javascript/echo.js';

import { dotpiConfigurationGet } from './configuration.js';
import { definitionGet } from './definition.js';

export function createConfigCommandDefine({program}) {
  program
    .command('create-config')
    .summary('create configuration files for installed modules')
    .description('Create configuration files installed modules.')
    .option('-r, --dotpi-root <path>', 'dotpi root path, to initialise environment')
    .option('-p, --prefix <path>', 'look for installed modules in this directory')
    .option('-v, --verbose [full]', 'print verbose output [full]')
    .action((modules, options, command) => createConfig(modules, { ...options, command }));
  ;

  return program;
}

export async function createConfig({
  dotpiRoot,
  prefix,
  verbose = 'short',
} = {}) {

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

  let installedModulesPath;
  let installedModulesDefinition;
  let installedModules;
  try {
    if (prefix) {
      installedModulesPath = prefix;
    } else {
      ({ modulesPath: installedModulesPath }
        = await dotpiConfigurationGet({ dotpiRoot, prefix }));
    }

    installedModulesDefinition = JSON.parse(
      await fs.readFile(path.resolve(installedModulesPath, 'package.json'))
    );
    installedModules = Object.keys(installedModulesDefinition.dependencies);
  } catch (error) {
    echo.error(`Failed to get installed modules: ${error.message}`);
    process.exit(1);
  }

  // use array to avoid escaping in command
  const dotpiRootOption = (dotpiRoot
    ? ['--dotpi-root', path.resolve(dotpiRoot)]
    : ''
  );
  const projectOption = (prefix
    ? ['--project', path.resolve(prefix)]
    : ''
  );

  // no parallelisation to create config files
  for (const module of installedModules) {
    try {
      const modulePath = path.resolve(installedModulesPath, 'node_modules', module);
      const moduleDefinition = JSON.parse(await fs.readFile(
        path.resolve(modulePath, 'package.json')
      ));

      if (moduleDefinition.scripts['create-config']) {
        if(verbose !== 'none') {
          echo.info(`Creating configuration for '${module}' in '${prefix}'`);
        }

        const output = await $({
          cwd: modulePath,
          env: { FORCE_COLOR: 'true' }, // do not remove colors
          verbose: (verbose === 'full' ? 'full' : 'none'),
        })`npm run create-config -- ${dotpiRootOption} ${projectOption}`;
      } else {
        console.log(`(No configuration file to create for '${module}')`);
      }


    } catch (error) {
      echo.error(`Failed to create configuration files for '${module}': ${error.message}`, error);
      process.exit(1);
    }

  }
}
