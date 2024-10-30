import fs from 'node:fs';
import path from 'node:path';

import prompts from 'prompts';
import chalk from 'chalk';

import filemap, {
  idRsaPrefix,
} from './constants.js';
import {
  onCancel,
  confirm,
} from './utils.js';

export async function configureHost(projectPath = null) {
  // This can be called programmaticaly
  if (projectPath === null) {
    if (isDotpiProject(CWD)) {
      projectPath = CWD;
    } else {
      const awswers = await chooseProject(CWD);
      projectPath = answers.projectPath;
    }
  }

  console.log(projectPath);
  return;

  console.log(chalk.yellow(`
To configure your machine for the "${projectName}" project, this script will:
- add the project specific SSH keys into your \`$HOME/.ssh\` directory
- add the project specific SSH config file into your \`$HOME/.ssh/config.d\` directory
  `));

  await confirm();



}

await configureHost();