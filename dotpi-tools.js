import { program } from 'commander';
import chalk from 'chalk';

import { greetings } from './src/utils.js';
import createProject from './src/create-project.js';
import installRpi from './src/install-rpi.js';

program
  .option('--create-config')
  .option('--install-rpi')
  // .option('--configure-host')
  // .option('--launch-manager');

program.parse();

const options = program.opts();

greetings();

if (options.createConfig) {
  await createProject();
} else if (options.installRpi) {
  await installRpi();
} else if (options.configureHost) {
  console.log(chalk.yellow('> configureHost is not implemented yet'));
} else if (options.launchManager) {
  console.log(chalk.yellow('> launchManager is not implemented yet'));
} else {
  // @todo prompt
}

