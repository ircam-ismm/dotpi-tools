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

export async function configureHost(projectName = null) {

  const test = await prompts({
    type: 'text',
    name: 'projectName',
    message: 'Select the project you want to configure on your machine:',
  }, { onCancel });

  if (projectName === null) {
    const entries = fs.readdirSync(filemap.projectsDir);
    const projects = entries.filter(entry => {
      return fs.statSync(path.join(filemap.projectsDir, entry)).isDirectory();
    });

    const answer = await prompts({
      type: 'select',
      name: 'projectName',
      message: 'Select the project you want to configure on your machine:',
      choices: projects.map(p => ({ title: p, value: p })),
    }, { onCancel });

    projectName = answer.projectName;
  }

  console.log(chalk.yellow(`
To configure your machine for the "${projectName}" project, this script will:
- add the project specific SSH keys into your \`$HOME/.ssh\` directory
- add the project specific SSH config file into your \`$HOME/.ssh/config.d\` directory
  `));

  await confirm();



}

await configureHost();