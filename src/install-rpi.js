import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { EOL } from 'node:os';

import prompts from 'prompts';
import chalk from 'chalk';

import {
  PATH_DOTPI_TMP_BASH,
  PATH_DOTPI_PREPARE_SD_CARD_BASH,
  CWD,
} from './constants.js';
import {
  title,
  confirm,
  onCancel,
  readBashVariable,
} from './utils.js'

export default async function installRpi(mocks = null) {
  title('Install a dotpi project on a Raspberry Pi');

  if (mocks) {
    prompts.inject(Object.values(mocks))
  }

  // get list of projects
  const projects = fs.readdirSync(CWD)
    .filter(f => fs.statSync(path.join(CWD, f)).isDirectory());

  const { projectName } = await prompts({
    type: 'select',
    name: 'projectName',
    message: 'Choose the project:',
    choices: projects.map(s => ({ title: s, value: s })),
  }, { onCancel });

  // find last instance number as stored by the shell script
  const projectPath = path.join(CWD, projectName);
  const dotpiTmpFile = path.join(projectPath, PATH_DOTPI_TMP_BASH);
  const nextInstanceNumber = readBashVariable('dotpi_instance_number', dotpiTmpFile) || 1;

  const { instanceNumber } = await prompts({
    type: 'number',
    name: 'instanceNumber',
    message: 'Raspberry Pi instance number:',
    initial: nextInstanceNumber,
  }, { onCancel });

  console.log('');

  if (!await confirm(mocks)) {
    return;
  }

  console.log('');
  console.log(chalk.yellow('> Preparing SD Card'));
  console.log('');

  const result = await new Promise(resolve => {
    // we can now execute the shell script
    const script = spawn(`${PATH_DOTPI_PREPARE_SD_CARD_BASH} --project "${projectPath}" --instance-number ${instanceNumber}`, {
      shell: '/bin/bash',
    });

    let lastLog = null;

    script.stdout.on('data', (data) => {
      data = data.toString();
      lastLog = data;
      process.stdout.write(data);
    });

    script.stderr.on('data', (data) => {
      process.stderr.write(data.toString());
    });

    script.on('close', (code) => {
      if (code !== 0) {
        console.log(chalk.yellow(`> Process exited with code ${code}`));
        return resolve(null);
      }

      // process last line to get ssh monitor command
      const lines = lastLog.split(EOL).filter(l => l.trim() !== '');
      const lastLine = lines[lines.length - 1];
      const cmd = `ssh ${lastLine.split('ssh ')[1]}`;
      // console.log('-----------');
      // console.log(cmd);
      resolve(cmd);
    });
  });

  if (result === null) {
    return;
  }

  console.log('');
  console.log(chalk.yellow(`> You can now put the SD card in the Raspberry Pi and power it on`));
  console.log('');

  const { monitorInstall } = await prompts({
    type: 'toggle',
    name: 'monitorInstall',
    message: 'Do you want to remotely monitor the installation?',
    initial: true,
    active: 'yes',
    inactive: 'no'
  }, { onCancel });

  if (!monitorInstall) {
    return;
  }

  // @todo - define with JIP how we can exit this properly
  // - error, ask to restart from scratch
  // - ok, congrats your raspberry is up and running
  await new Promise(resolve => {
    console.log('');
    console.log(chalk.yellow('> Waiting for the Pi to connect, this might take a while'));
    console.log('');

    const script = spawn(result, { shell: '/bin/bash' });

    script.stdout.on('data', (data) => {
      // if (data mathces 'INFO: System prepared') {
      //   script.kill();
      // }

      process.stdout.write(data.toString());
    });

    script.stderr.on('data', (data) => {
      process.stderr.write(data.toString());
    });

    script.on('close', (code) => {
      if (code !== 0) {
        console.log(chalk.yellow(`> Process exited with code ${code}`));
        return resolve();
      }

      resolve();
    });
  });
}