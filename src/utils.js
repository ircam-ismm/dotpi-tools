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
  const homepage = pkg.homepage;

  console.log(chalk.grey(`[dotpi#v${packageVersion()}]`));
  console.log('');
  console.log(chalk.yellow(`> welcome to dotpi`));
  // @todo - update
  console.log('');
  console.log(`- homepage: ${chalk.cyan(`${homepage}`)}`);
  console.log(`- issues: ${chalk.cyan(`${homepage}/issues`)}`);

  if (platform() !== 'darwin') {
    console.log(chalk.yellow(`
* WARNING: these tools have only been tested on Mac so far, you may encounter issues
* on other platform, and in particular on windows.
*
* Any PR welcome! ${homepage}
*   `))
  }
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

export function isDotpiProject(pathname = CWD) {
  const dotpiFile = path.join(pathname, PATH_DOTPI_FILE);
  fs.statSync(pathname).isDirectory() && fs.existsSync(dotpiFile)
}

export function listDotpiProjects(pathname = CWD) {
  return fs.readdirSync(pathname)
    .filter(filename => isDotpiProject(path.join(pathname, filename)))
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

  const { projectPath } = await prompts({
    type: 'select',
    name: 'projectPath',
    message: 'Select a dotpi project',
    choices: projects.map(value => ({ title: path.basename(value), value })),
  });

  return projectPath;
}