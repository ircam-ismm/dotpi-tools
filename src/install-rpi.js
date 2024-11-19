import path from 'node:path';
import { spawn, execSync } from 'node:child_process';

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
  isDotpiProject,
  chooseProject,
  isWindowsWsl,
} from './utils.js'

export default async function installRpi(mocks = null) {
  title('Install a dotpi project on a Raspberry Pi');

  if (mocks) {
    prompts.inject(Object.values(mocks))
  }

  let projectPath;

  if (isDotpiProject(CWD)) {
    projectPath = CWD;
  } else {
    projectPath = await chooseProject(CWD);
  }

  const dotpiTmpFile = path.join(projectPath, PATH_DOTPI_TMP_BASH);
  const nextInstanceNumber = readBashVariable('dotpi_instance_number', dotpiTmpFile) || 1;

  const { instanceNumber } = await prompts({
    type: 'number',
    name: 'instanceNumber',
    message: 'Raspberry Pi instance number:',
    initial: nextInstanceNumber,
  }, { onCancel });

  // If linux in window (i.e. WSL), we weed the drive letter to mount it
  let bootfsDriveLetter = null;

  if (isWindowsWsl()) {
    const result = await prompts({
      type: 'text',
      name: 'bootfsDriveLetter',
      message: 'Enter the drive letter of the "bootfs" SD card:',
      initial: 'E',
      validate: val => /[A-Za-z]{1}/.test(val),
      format: val => val.toUpperCase(),
    }, { onCancel });

    bootfsDriveLetter = result.bootfsDriveLetter;
  }

  console.log('');

  if (!await confirm(mocks)) {
    return;
  }

  console.log('');
  console.log(chalk.yellow('> Preparing SD Card'));
  console.log('');

  const result = await new Promise(resolve => {
    let cmd = `${PATH_DOTPI_PREPARE_SD_CARD_BASH} --project "${projectPath}" --instance-number ${instanceNumber}`;

    if (bootfsDriveLetter !== null) {
      cmd += ` --bootfs-drive-letter "${bootfsDriveLetter}"`;
    }

    console.log(cmd);
    // we can now execute the shell script
    const script = spawn(cmd, { shell: '/bin/bash' });
    script.stdout.on('data', data => process.stdout.write(data.toString()));
    script.stderr.on('data', data => process.stderr.write(data.toString()));

    script.on('close', (code) => {
      if (code !== 0) {
        console.log(chalk.yellow(`> Process exited with code ${code}`));
        return resolve(false);
      }

      resolve(true)
    });
  });

  if (!result) {
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
    const DOTPI_ETC = path.normalize('tmp/file-system/opt/dotpi/etc');
    const hostname = readBashVariable(
      'dotpi_instance_hostname',
      path.join(projectPath, DOTPI_ETC, 'dotpi_environment_instance.bash')
    );

    console.log('');
    console.log(chalk.cyan('> Waiting for the Pi to connect (this might take a few minutes)'));
    console.log(chalk.cyan(`> hostname: ${hostname}.local`));
    console.log('');

    // wait for the device to be online before launching ssh command (required for Linux)
    let errored = true;

    while (errored) {
      try {
        execSync(`ping -c 1 -t 10 ${hostname}.local &> /dev/null`, { shell: '/bin/bash' });
        errored = false;
      } catch (err) {
        process.stdout.write('.');
      }
    }

    console.log('');
    console.log('');
    console.log(chalk.cyan('> Pi connected, reading log file:'));
    console.log('');

    const script = spawn(
      `ssh pi@${hostname}.local 'tail -f /opt/dotpi/var/log/dotpi_prepare_system_*.log'`,
      { shell: '/bin/bash' }
    );

    script.stdout.on('data', data => process.stdout.write(data.toString()));
    script.stderr.on('data', data => process.stderr.write(data.toString()));
    script.on('close', (code) => {
      if (code !== 0) {
        console.log(chalk.yellow(`> Process exited with code ${code}`));
        return resolve();
      }

      resolve();
    });
  });
}