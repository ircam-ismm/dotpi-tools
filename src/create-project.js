import fs from 'node:fs';
import path from 'node:path';
import { tmpdir } from 'node:os';
import { execSync } from 'node:child_process';

import prompts from 'prompts';
import chalk from 'chalk';

import * as echo from '@dotpi/javascript/echo.js';
import * as bash from '@dotpi/javascript/bash.js';
import { install as moduleInstall } from '@dotpi/module/install.js';
import { createConfig as moduleCreateConfig } from '@dotpi/module/createConfig.js';
import { definitionGet as moduleDefinitionGet } from '@dotpi/module/definition.js';

import {
  title,
  renderTemplate,
  readBashArray,
  readBashVariable,
  processPath,
  confirm,
  onCancel,
  packageVersion,
  isPrivateSshKey,
  isDotpiProject,
} from './utils.js';
import {
  DOTPI_ROOT,
  // path of the files inside the final project
  PATH_DOTPI_PROJECT_BASH,
  PATH_DOTPI_SECRETS_BASH,
  PATH_SSH_DIRECTORY,
  PATH_NETWORK_DIRECTORY,
  PATH_GITIGNORE,
  PATH_README,
  PATH_DOTPI_FILE,
  PATH_PACKAGE_JSON,
  // utilities
  DOTPI_SSH_KEYS_PREFIX,
  PROJECT_NAME_REGEXP,
  // this must be put in gitignore
  PATH_DOTPI_TMP_DIRECTORY,
  // where the command is executed
  CWD,
} from './constants.js';
import configureHost from './configure-host.js';

export async function prepareProject(data = {}, mocks = null) {
  title(`Prepare dotpi project`);

  if (mocks) {
    prompts.inject(Object.values(mocks));
  }

  const { projectName, password } = await prompts([
    {
      type: 'text',
      name: 'projectName',
      message: 'Name of your dotpi project:',
      validate: value => {
        const projectPath = path.join(CWD, value);

        if (!PROJECT_NAME_REGEXP.test(value)) {
          return 'Please provide a valid project name. A valid project name must contain only lower case letters, digits, - and _';
        } else if (fs.existsSync(projectPath) && fs.statSync(projectPath).isDirectory()) {
          return `A project named "${value}" already exists`;
        }

        return true;
      },
    }, {
      type: 'text',
      name: 'password',
      message: 'Define a password for your dotpi / raspberry pi modules:',
      validate: input => input.length < 6 ? 'Minimum length of 6 characters' : true,
    },
  ], { onCancel });

  data.projectName = projectName;
  data.files[PATH_DOTPI_SECRETS_BASH] = renderTemplate('dotpi_secrets.bash', { password });

  return data;
}

/**
 * @todo could be used to configure a specific dotpi instance too
 */
export async function configureProject(data, mocks = null) {
  title(`Configure system`);

  if (mocks) {
    prompts.inject(Object.values(mocks));
  }

  const { projectName } = data;
  const version = packageVersion();

  const answers = await prompts([
    {
      type: 'select',
      name: 'soundCard',
      message: 'Choose your soundcard:',
      choices: readBashArray('dotpi_audio_device_supported').map(s => ({ title: s, value: s })),
    },
    {
      type: 'text',
      name: 'nodeVersion',
      message: 'Node.js version:',
      initial: 'lts',
      format: val => val.trim(),
    },
    {
      type: 'text',
      name: 'timeZone',
      message: 'Time zone:',
      initial: 'Europe/Paris',
      format: val => val.trim(),
    },
    {
      type: 'text',
      name: 'wifiCountryCode',
      message: 'WiFi country code:',
      initial: 'FR',
      format: val => val.trim(),
    },
    {
      type: 'text',
      name: 'keyMap',
      message: 'Key map:',
      initial: 'fr',
      format: val => val.trim(),
    },
    {
      type: 'toggle',
      name: 'installDotpiManager',
      message: 'Install the dotpi-manager module?',
      initial: true,
      active: 'yes',
      inactive: 'no'
    },
    {
      type: 'toggle',
      name: 'installDotpiLed',
      message: 'Install the dotpi-led module?',
      initial: false,
      active: 'yes',
      inactive: 'no'
    },
  ], { onCancel });

  data.files[PATH_DOTPI_PROJECT_BASH] = renderTemplate('dotpi_project.bash', {
    projectName,
    version,
    ...answers,
  });

  // @todo - Configure a specific instance

  return data;
}

export async function configureSSH(data, mocks = null) {
  title(`Configure SSH keys`);

  if (mocks) {
    prompts.inject([mocks.createOrResuse]);
  }

  const { createOrReuse } = await prompts({
    type: 'select',
    name: 'createOrReuse',
    message: 'Do you want to:',
    choices: [
      { title: 'Create new SSH keys (recommended)', value: 'create' },
      { title: 'Use existing SSH keys', value: 'reuse' },
    ],
    initial: 0,
  }, { onCancel });

  const { projectName } = data;
  const hostnamePrefix = readBashVariable('dotpi_hostname_prefix');

  let keyBasename = null;

  switch (createOrReuse) {
    case 'create': {
      // create tmp dir and generate some SHH key pair
      keyBasename = `${DOTPI_SSH_KEYS_PREFIX}_${hostnamePrefix}_${projectName}`;
      const tmp = fs.mkdtempSync(path.join(tmpdir(), `${projectName}-`));
      const generatedPrivateKeyPath = path.join(tmp, keyBasename);
      execSync(`ssh-keygen -f ${generatedPrivateKeyPath} -t rsa -b 4096  -q -N ""`);

      // retreive generated keys and store in data
      const privateKeyPath = path.join(PATH_SSH_DIRECTORY, keyBasename);
      const privateKey = fs.readFileSync(generatedPrivateKeyPath).toString();
      data.files[privateKeyPath] = privateKey;

      const generatedPublicKeyPath = `${generatedPrivateKeyPath}.pub`;
      const publicKeyPath = path.join(PATH_SSH_DIRECTORY, `${keyBasename}.pub`);
      const publicKey = fs.readFileSync(generatedPublicKeyPath).toString();
      data.files[publicKeyPath] = publicKey;

      // delete tmp dir
      fs.rmSync(tmp, { recursive: true, force: true });
      break;
    }
    case 'reuse': {
      const { originalPrivateKeyPath } = await prompts({
        type: 'text',
        name: 'originalPrivateKeyPath',
        message: 'Path to the private key:',
        validate: val => {
          return isPrivateSshKey(processPath(val))
            ? true
            : `Given file is not a valid SHH private key`;
        },
        format: val => processPath(val),
      }, { onCancel });

      const privateKey = fs.readFileSync(originalPrivateKeyPath).toString();
      const privateKeyPath = path.join(PATH_SSH_DIRECTORY, path.basename(originalPrivateKeyPath));
      data.files[privateKeyPath] = privateKey;

      const originalPublicKeyPath = `${originalPrivateKeyPath}.pub`;
      const publicKey = fs.readFileSync(originalPublicKeyPath).toString();
      const publicKeyPath = path.join(PATH_SSH_DIRECTORY, path.basename(originalPublicKeyPath));
      data.files[publicKeyPath] = publicKey;

      // for config file
      keyBasename = path.basename(originalPrivateKeyPath);
      break;
    }
  }

  const configPath = path.join(PATH_SSH_DIRECTORY, 'config.d', `${hostnamePrefix}-${projectName}`);

  data.files[configPath] = renderTemplate('ssh_config', {
    projectName,
    hostnamePrefix,
    keyBasename,
  });

  return data;
}

export async function configureWiFi(data, mocks = null) {
  title(`Configure WiFi connection`);

  if (mocks) {
    prompts.inject(Object.values(mocks));
  }

  const wifiApInstanceSuffix = '-${dotpi_instance_number}';

  // https://people.freedesktop.org/~lkundrak/nm-dbus-api/nm-settings.html
  // @note - let's consider we always use wpa-psk for now

  const computedValues = {};

  const onSubmit = (prompt, answer, answers) => {
    Object.assign(computedValues, { [prompt.name]: answer });
    if (answers.wifiMode === 'ap') {
      // will be specialised with instance number
      Object.assign(computedValues, { connectionIsTemplate: true } );
    }
  };

  const answers = await prompts([
    {
      type: 'select',
      name: 'wifiMode',
      message: 'Select WiFi mode:',
      choices: [
        { title: 'Connect to existing WiFi network (recommended)', value: 'infrastructure' },
        { title: 'Create Access Point', value: 'ap' },
      ],
      initial: 0,
    },
    {
      type: 'text',
      name: 'wifiSsid',
      message: 'Wifi name (SSID):',
      validate: value => {

        let ssid = value;

        // remove instance number suffix
        const instanceNumberRegexp = new RegExp(
          // escape dollar sign for regexp
          wifiApInstanceSuffix.replace(/\$/g, '\\$'),
          // replace all occurrences
          'g'
        );

        ssid = ssid.replace(instanceNumberRegexp, '');
        let wifiId = ssid
          .toLowerCase()
          .replace(/[^a-z0-9\-_]/g, '-');

        if (computedValues.wifiMode === 'ap') {
          // reserve size for instance number substitution
          ssid += '-0000';

          // for NetworkManager identifier
          wifiId += '-ap';
        }

        const ssidSize = new Blob([ssid]).size;
        if (ssidSize === 0) {
          return 'Please provide a non-empty SSID';
        } else if(ssidSize > 32) {
          return `'${ssid}' is too long (more than 32 bytes)`;
        }

        const configPath = path.join(PATH_NETWORK_DIRECTORY, wifiId);

        // @TODO: file is created later, this test is bypassed
        if (fs.existsSync(configPath)) {
          return `A WiFi configuration named "${wifiId}" already exists`;
        }

        Object.assign(computedValues, { wifiId });
        return true;
      },
      initial: (previous, values) => {
        if (values.wifiMode === 'ap') {
          return `dotpi-${data.projectName}${wifiApInstanceSuffix}`;
        }
        return null;
      }
    },
    {
      type: 'select',
      name: 'wifiBand',
      message: 'Select WiFi band:',
      choices: [
        { title: 'Automatic', value: 'automatic' },
        { title: '2.4 GHz only', value: 'bg' },
        { title: '5 GHz only', value: 'a' },
      ],
      initial: 0,
    },
    {
      type: 'text',
      name: 'wifiPsk',
      message: 'Wifi password:',
      validate: value => {
        if (new Blob([value]).size < 8) {
          return `'${value}' is too short (less than 8 bytes)`;
        }

        if (new Blob([value]).size > 63) {
          return `'${value}' is too long (more than 63 bytes)`;
        }

        return true;
      },
    },
  ], { onCancel, onSubmit });

  Object.assign(answers, computedValues);

  const { wifiId, wifiMode, connectionIsTemplate } = answers;
  let connectionPath = path.join(PATH_NETWORK_DIRECTORY, `${wifiId}.nmconnection`);

  if (connectionIsTemplate) {
    connectionPath += '.template';
  }

  let connectionConfig = null;

  switch (wifiMode) {
    case 'infrastructure': {
      const { wifiPriority } = await prompts({
        type: 'number',
        name: 'wifiPriority',
        message: 'WiFi priority (higher number means higher priority):',
        min: -2147483648, // int32
        max: 2147483647,
        round: 0,
        initial: 0,
      }, { onCancel, onSubmit });

      connectionConfig = renderTemplate('infrastructure.nmconnection', {
        wifiPriority,
        ...answers,
      });
      break;
    }
    case 'ap': {
      connectionConfig = renderTemplate('ap.nmconnection.template', {
        ...answers,
      });
      break;
    }
    default: {
      throw new Error(`Cannot generate WiFi nmconnection file: Invalid mode ${wifiMode}`);
    }
  }

  data.files[connectionPath] = connectionConfig;

  // ask for creating another WiFi config
  const { createAnotherConnection } = await prompts({
    type: 'toggle',
    name: 'createAnotherConnection',
    message: 'Do you want to configure another WiFi connection?',
    initial: false,
    active: 'yes',
    inactive: 'no'
  });

  if (createAnotherConnection) {
    await configureWiFi(data, mocks);
  }

  return data;
}


export async function injectUtilityFiles(data) {
  const { projectName } = data;

  data.files[PATH_DOTPI_FILE] = JSON.stringify({ dotpiToolsVersion: packageVersion() }, null, 2);

  data.files[PATH_GITIGNORE] = renderTemplate('gitignore', {
    PATH_DOTPI_SECRETS_BASH,
    PATH_SSH_DIRECTORY,
    PATH_NETWORK_DIRECTORY,
    PATH_DOTPI_TMP_DIRECTORY,
  });

  data.files[PATH_README] = renderTemplate('README.md', {
    projectName,
    PATH_DOTPI_SECRETS_BASH,
    PATH_SSH_DIRECTORY,
    PATH_NETWORK_DIRECTORY,
  });

  data.files[PATH_PACKAGE_JSON] = renderTemplate('package.json', {
    projectName,
  });
}

export async function persistProject(data, mocks = null) {
  title('Save dotpi project');

  const { projectName } = data;
  const projectPath = path.join(CWD, projectName);

  console.log(chalk.yellow(`> Your project will be created in "${projectPath}"`));
  if (!await confirm(mocks)) {
    return;
  }

  console.log('');
  console.log(chalk.grey(`- Creating project directory: ${projectPath}`));
  fs.mkdirSync(projectPath, { recursive: true });

  for (let file in data.files) {
    const pathname = path.join(projectPath, file);
    const content = data.files[file];
    console.log(chalk.grey(`- Writing project file: ${pathname}`));
    // ensure directory exists
    fs.mkdirSync(path.dirname(pathname), { recursive: true });
    fs.writeFileSync(pathname, content);
  }

  title(`Project ${projectName} successfully created!`);
}

export async function installModulesInProject(data) {
  title('Install modules in project');

  const dotpiRoot = DOTPI_ROOT;
  const dotpiInit = await bash.dotpiInitSourceFileGet({ dotpiRoot });

  const { projectName } = data;
  const projectPath = path.join(CWD, projectName);
  const projectDotpiInit = path.join(projectPath, PATH_DOTPI_PROJECT_BASH);

  const modules = await bash.variableRead({
    sourceFiles: [
      dotpiInit,
      projectDotpiInit,
    ],
    variable: 'dotpi_module_install',
  });

  await moduleInstall(modules, {
    dotpiRoot,
    prefix: projectPath,
    verbose: 'short',
  })

}

export async function generateConfigFilesInProject(data) {
  title('Generate config files for modules in project');

  const dotpiRoot = DOTPI_ROOT;
  const { projectName } = data;
  const projectPath = path.join(CWD, projectName);

  await moduleCreateConfig({
    dotpiRoot,
    prefix: projectPath,
    verbose: 'short',
  })

}

// Wrap it all
export default async function createProject() {
  try {
    if (isDotpiProject()) {
      console.log('');
      console.log(chalk.yellow(`> Cannot create a dotpi project in this directory, it already contains a dotpi project`));
      console.log('Aborting...');
      process.exit(0);
    }

    const data = {
      projectName: null,
      files: {},
    };

    await prepareProject(data);
    await configureProject(data);
    await configureSSH(data);
    await configureWiFi(data);
    await injectUtilityFiles(data);
    await persistProject(data);

    await installModulesInProject(data);
    await generateConfigFilesInProject(data);

    title('Configure local machine for project');

    const { configure } = await prompts({
      type: 'toggle',
      name: 'configure',
      message: 'Do you want to configure your local machine for this project?',
      initial: true,
      active: 'yes',
      inactive: 'no'
    }, { onCancel });

    const { projectName } = data;

    if (configure) {
      const projectPath = path.join(CWD, projectName);
      await configureHost(projectPath);
    }

    console.log(`\
> The dotpi project "${projectName}" is ready to be installed on some Raspberry Pi
>
> Next Step: plug-in a SD Card with a Raspberry Pi OS (Lite) installed and run:
> ${chalk.yellow('dotpi-tools --install-rpi')}
  `);
  } catch (error) {
    echo.error(`Error while creating dotpi project: ${error.message}`, error);
    process.exit(1);
  }
}
