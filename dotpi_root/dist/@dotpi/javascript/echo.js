import chalk from 'chalk';

export function info(...message) {
  console.log(chalk.green('INFO:'), ...message);
}

export function warning(...message) {
  console.log(chalk.yellow('WARNING:'), ...message);
}

export function error(...message) {
  console.log(chalk.red('ERROR:'), ...message);
}
