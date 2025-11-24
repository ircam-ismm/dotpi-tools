#!/usr/bin/env node
import { program } from 'commander';
import chalk from 'chalk';

import { greetings } from './src/utils.js';
import createProject from './src/create-project.js';
import installRpi from './src/install-rpi.js';
import configureHost from './src/configure-host.js';
import { packageVersion } from './src/utils.js';

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
  console.log(chalk.yellow('> launchManager is not implemented yet'));
} else {
  // @todo prompt
  console.log(chalk.yellow('> Invalid option:'));
  console.log(options);
}


if (displayGreetings) {
  greetings();
}
