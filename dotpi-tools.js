#!/usr/bin/env node
import { program } from 'commander';

import { pnpmResolveInPath } from '@dotpi/module/pnpm.js';
import * as echo from '@dotpi/javascript/echo.js';

import { greetings } from './src/utils.js';
import createProject from './src/create-project.js';
import installRpi from './src/install-rpi.js';
import configureHost from './src/configure-host.js';
import { packageVersion } from './src/utils.js';

if(!await pnpmResolveInPath()) {
  echo.error('> pnpm is not in path: please install pnpm before.');
  process.exit(1);
}

program
  .option('--create-project', 'create a new dotpi project')
  .option('--install-rpi', 'install a dotpi project on a Raspberry Pi SD card')
  .option('--configure-host', 'configure the host system for dotpi development')
  .option('-v, --version', 'display version information of this tool')
  ;
  // .option('--launch-manager');

program.parse();

const options = program.opts();

let displayGreetings = true;

if (Object.keys(options).length === 0) {
  console.log('');
  program.help();
}

if (options.createProject) {
  await createProject();
} else if (options.installRpi) {
  await installRpi();
} else if (options.configureHost) {
  await configureHost();
} else if (options.version) {
  displayGreetings = false;
  console.log(packageVersion());
} else if (options.launchManager) {
  echo.error('> launchManager is not implemented yet');
  exit(2);
} else {
  // @todo prompt
  echo.error('> Invalid option:');
  console.log(options);
  exit(3);
}


if (displayGreetings) {
  greetings();
}
