import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';
import { EOL, platform } from 'node:os';

import prompts from 'prompts';
import chalk from 'chalk';
import compile from 'template-literal';

import {
  LIB_ROOT,
  CWD,
  HOME,
  PATH_DOTPI_INIT_BASH,
  PATH_DOTPI_FILE,
  PATH_TEMPLATE_DIRECTORY,
} from './constants.js';

export const packageVersion = () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(LIB_ROOT, 'package.json')));
  return pkg.version;
}

export function greetings() {
  const pkg = JSON.parse(fs.readFileSync(path.join(LIB_ROOT, 'package.json')));

  console.log(chalk.grey(`[${pkg.name}#v${pkg.version}]`));
  console.log('');
  console.log(chalk.yellow(`> welcome to ${pkg.name}`));
  // @todo - update
  console.log('');
  console.log(`- documentation: ${chalk.cyan(`${pkg.homepage}`)}`);
  console.log(`- issues: ${chalk.cyan(`${pkg.bugs.url}`)}`);

//   if (platform() !== 'darwin') {
//     console.log(chalk.yellow(`
// * WARNING: these tools have only been tested on Mac so far, you may encounter issues
// * on other platform, and in particular on windows.
// *
// * Any PR welcome! ${homepage}
// *   `))
//   }
}

export function title(str) {
  console.log('');
  console.log(chalk.cyan(`> [dotpi] ${str}`));
  console.log('');
}

export function renderTemplate(templatePath, data = {}) {
  const pathname = path.join(PATH_TEMPLATE_DIRECTORY, templatePath);

  if (!fs.existsSync(pathname)) {
    throw new Error(`Cannot execute 'renderTemplate': template file '${pathname}' not found`);
  }

  const template = fs.readFileSync(pathname);
  const render = compile(template);

  return render(data);
}

const homeRE = new RegExp(`^${HOME}`);
export function formatPath(pathname) {
  return pathname.replace(homeRE, '~');
}

export function isDotpiProject(pathname = CWD) {
  const dotpiFile = path.join(pathname, PATH_DOTPI_FILE);
  return fs.statSync(pathname).isDirectory() && fs.existsSync(dotpiFile)
}

export function listDotpiProjects(pathname = CWD) {
  return fs.readdirSync(pathname)
    .map(filename => path.join(pathname, filename))
    .filter(filename => isDotpiProject(filename))
}

export function isPrivateSshKey(pathname) {
  if (fs.existsSync(pathname) && fs.statSync(pathname).isFile()) {
    const content = fs.readFileSync(pathname).toString();
    return content.startsWith(`-----BEGIN OPENSSH PRIVATE KEY-----`);
  } else {
    return false;
  }
}

export function isWindowsWsl() {
  const buffer = execSync('uname -a', { shell: '/bin/bash' });
  const unameString = buffer.toString();
  return /[Mm]icrosoft/.test(unameString);
}

/**
 * Allow using ~ or $HOME into given pathname
 * @param {*} pathname
 * @returns
 */
export function processPath(pathname) {
  const buffer = execSync(`echo ${pathname}`);
  return buffer.toString().trim();
}

// -------------------------------------------------------
// Bash utils
// -------------------------------------------------------
export function readBashVariable(varname, filename = PATH_DOTPI_INIT_BASH) {
  if (!fs.existsSync(filename)) {
    return '';
  }

  return execSync(`source ${filename}; echo "\${${varname}}"`, {
    shell: '/bin/bash',
  }).toString().trim();
}

export function readBashArray(varname, filename = PATH_DOTPI_INIT_BASH) {
  if (!fs.existsSync(filename)) {
    return [];
  }

  return execSync(`source ${filename}; for i in "\${${varname}[@]}" ; do echo "\${i}" ; done`, {
    shell: '/bin/bash',
  }).toString().trim().split(EOL)
}

// -------------------------------------------------------
// Prompts utils
// -------------------------------------------------------
export const onCancel = () => process.exit();

// maybe useless - tbd
export async function confirm(mocks = null) {
  // always proceed in tests
  if (mocks) {
    prompts.inject([true]);
  }

  const { proceed } = await prompts({
    type: 'toggle',
    name: 'proceed',
    message: 'Continue?',
    initial: true,
    active: 'yes',
    inactive: 'no',
  }, { onCancel });

  // do not exit process in tests
  if (!proceed) {
    console.log('Aborting...');
    process.exit(0);
  }

  return proceed;
}
export async function chooseProject(basePathname, mocks = null) {
  const projects = listDotpiProjects(basePathname);

  if (projects.length === 0) {
    console.log(chalk.yellow(`> No dotpi project found in ${basePathname}`));
    console.log('');
    console.log('Aborting...');
    process.exit(0);
  }

  const { projectPath } = await prompts({
    type: 'select',
    name: 'projectPath',
    message: 'Select a dotpi project',
    choices: projects.map(value => ({ title: path.basename(value), value })),
  }, { onCancel });

  return projectPath;
}
