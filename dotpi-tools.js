#!/usr/bin/env node
import { program } from 'commander';
import chalk from 'chalk';

import { greetings } from './src/utils.js';
import createProject from './src/create-project.js';
import installRpi from './src/install-rpi.js';
import configureHost from './src/configure-host.js';

program
  .option('--create-project')
  .option('--install-rpi')
  .option('--configure-host')
  // .option('--launch-manager');

program.parse();

const options = program.opts();

greetings();

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
} else if (options.launchManager) {
  console.log(chalk.yellow('> launchManager is not implemented yet'));
} else {
  // @todo prompt
  console.log(chalk.yellow('> Invalid option:'));
  console.log(options);
}

