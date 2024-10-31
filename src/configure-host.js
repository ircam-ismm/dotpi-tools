import fs from 'node:fs';
import path from 'node:path';
import { EOL } from 'node:os';

import prompts from 'prompts';
import chalk from 'chalk';

import {
  CWD,
  HOME,
  LIB_ROOT,
  PATH_DOTPI_PROJECT_BASH,
  PATH_SSH_DIRECTORY,
} from './constants.js';
import {
  onCancel,
  formatPath,
  confirm,
  isDotpiProject,
  isPrivateSshKey,
  chooseProject,
  title,
  readBashVariable,
} from './utils.js';

// # Notes
// - SSH files permissions: https://jonasbn.github.io/til/ssh/permissions_on_ssh_folder_and_files.html

export default async function configureHost(projectPath = null) {
  title('Install SSH keys on local machine');

  // Allow configureHost to be called programmatically
  if (projectPath === null) {
    if (isDotpiProject(CWD)) {
      projectPath = CWD;
    } else {
      projectPath = await chooseProject(CWD);
    }
  }

  const testing = null;

  const projectName = readBashVariable('dotpi_project_name', path.join(projectPath, PATH_DOTPI_PROJECT_BASH));
  const projectSshPath = path.join(projectPath, PATH_SSH_DIRECTORY);

  const targetSshPath = testing
    ? path.join(LIB_ROOT, 'test', 'ssh-test-output')
    : path.join(HOME, '.ssh');

  console.log(chalk.yellow(`> Project: "${projectName}" | directory: ${formatPath(projectPath)}`));
  console.log(`
To configure your machine for the "${projectName}" dotpi project, this script will automatically:

1) copy the project specific SSH private and public keys into your \`$HOME/.ssh\` directory if they do not already exist
2) add the project specific SSH private key to the ssh-agent
3) copy the project specific SSH config file into your \`$HOME/.ssh/config.d\` directory if it does not exists
4) update or create your \`$HOME/.ssh/config\` file to automatically include all config files located in \`$HOME/.ssh/config.d\` if needed

If you prefer to do this manually, you can refer to the following documentation:
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=mac#adding-your-ssh-key-to-the-ssh-agent
- https://jonasbn.github.io/til/ssh/permissions_on_ssh_folder_and_files.html

You will be able to find all the relevant files in: ${formatPath(projectSshPath)}
  `);

  if (!await confirm(testing)) {
    return;
  }

  title('1) Copy project SSH keys');

  const files = fs.readdirSync(projectSshPath)
    .filter(filename => fs.statSync(path.join(projectSshPath, filename)).isFile())
    .map(filename => path.join(projectSshPath, filename));

  const srcPrivateKey = files.find(filename => isPrivateSshKey(filename));

  if (!srcPrivateKey) {
    console.log(chalk.yellow(`> No valid SSH private key found in ${formatPath(projectSshPath)}`));
    console.log('Aborting...');
    return;
  }

  console.log(chalk.grey(`> Found project private SSH key: ${formatPath(srcPrivateKey)}`));

  const srcPublicKey = `${srcPrivateKey}.pub`;

  if (!fs.existsSync(srcPublicKey) || !fs.statSync(srcPublicKey).isFile()) {
    console.log(chalk.yellow(`> No valid SSH public key found in ${formatPath(projectSshPath)}`));
    console.log('Aborting...');
    return;
  }

  console.log(chalk.grey(`> Found project public SSH key: ${formatPath(srcPublicKey)}`));

  if (!fs.existsSync(targetSshPath)) {
    console.log(chalk.grey(`> Create directory: ${targetSshPath}`));
    fs.mkdirSync(targetSshPath);
  }

  const distPrivateKey = path.join(targetSshPath, path.basename(srcPrivateKey));
  const distPublicKey = path.join(targetSshPath, path.basename(srcPublicKey));

  if (!fs.existsSync(distPrivateKey) && !fs.existsSync(distPublicKey)) {
    // copy ssh keys
    console.log(chalk.grey(`> Copy private key "${path.basename(srcPrivateKey)}" into "${formatPath(targetSshPath)}" with 600 permissions`));
    fs.copyFileSync(srcPrivateKey, distPrivateKey);
    fs.chmodSync(distPrivateKey, 0o600);

    // copy ssh keys
    console.log(chalk.grey(`> Copy public key "${path.basename(srcPublicKey)}" into "${formatPath(targetSshPath)}" with 644 permissions`));
    fs.copyFileSync(srcPublicKey, distPublicKey);
    fs.chmodSync(distPublicKey, 0o644);
  } else {
    console.log(chalk.grey(`> SSH keys with same name found in "${formatPath(targetSshPath)}", skip...`));
  }


  title('2) Copy project config file');

  const projectConfigdPath = path.join(projectSshPath, 'config.d');
  const targetConfigdPath = path.join(targetSshPath, 'config.d');
  const srcProjectConfigFile = fs.readdirSync(projectConfigdPath)
    .map(filename => path.join(projectConfigdPath, filename))
    .find(filename => filename.endsWith(projectName))

  if (srcProjectConfigFile) {
    console.log(chalk.grey(`> Found project config file: ${formatPath(srcProjectConfigFile)}`));

    if (!fs.existsSync(targetConfigdPath)) {
      console.log(chalk.grey(`> Create directory: "${formatPath(targetConfigdPath)}"`));
      fs.mkdirSync(targetConfigdPath);
    }

    const targetProjectConfigFile = path.join(targetConfigdPath, path.basename(srcProjectConfigFile));

    if (!fs.existsSync(targetProjectConfigFile)) {
      console.log(chalk.grey(`> Copy project config file "${path.basename(srcProjectConfigFile)}" into "${formatPath(targetConfigdPath)}" with 644 permissions`));
      fs.copyFileSync(srcProjectConfigFile, targetProjectConfigFile);
      fs.chmodSync(targetProjectConfigFile, 0o644);
    } else {
      console.log(chalk.grey(`> Project config file with same name found in "${formatPath(targetConfigdPath)}", skip...`));
    }
  } else {
    console.log(chalk.grey(`> No project config file found in "${formatPath(projectConfigdPath)}", skip...`));
  }

  const includeString = 'Include config.d/*';
  title(`3) Check .ssh/config "${includeString}"`);

  const sshConfigFile = path.join(targetSshPath, 'config');

  if (!fs.existsSync(sshConfigFile)) {
    console.log(chalk.grey(`> Create SSH config file "${formatPath(sshConfigFile)}" with 600 permissions`));
    fs.writeFileSync(sshConfigFile, includeString, {
      encoding: 'utf8',
      mode: 0o600,
    });
  } else {
    console.log(chalk.grey(`> Found SSH config file "${formatPath(sshConfigFile)}", check "${includeString}"`));

    const content = fs.readFileSync(sshConfigFile);
    const includeRe = new RegExp(includeString, 'm');
    const included = includeRe.test(content);

    if (!included) {
      console.log(chalk.grey(`> "${includeString}" not found in "${formatPath(sshConfigFile)}", inject directive`));
      const newContext = `\
  ${includeString}

  ${content}
  `;
      fs.writeFileSync(sshConfigFile, newContext, {
        encoding: 'utf8',
        mode: 0o600,
      });
    } else {
      console.log(chalk.grey(`> "${includeString}" found in "${formatPath(sshConfigFile)}", skip...`));
    }
  }

  console.log('');
  // title(`4) Check .ssh/config "${includeString}"`);
  // cleaning for tests
  // fs.rmSync(distPrivateKey);
  // fs.rmSync(distPublicKey);
}
