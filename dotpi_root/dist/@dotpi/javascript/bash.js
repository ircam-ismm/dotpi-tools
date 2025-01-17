import nodePath from 'node:path';

import{ $ } from 'execa';

import { dotpiRootGet } from './system.js';

export async function dotpiInitSourceFileGet({
  dotpiRoot,
} = {}) {
  dotpiRoot ??= await dotpiRootGet();

  return nodePath.resolve(dotpiRoot, 'share', 'dotpi_init.bash');
}

export async function sourceAndExecute({
  sourceFiles = [],
  sourceFile,
  uid, // optional to run as another user, see user/regularUserIdGet
  command = ':', // default to no-op
} = {}) {

  try {
    let _sourceFiles = [...sourceFiles];
    if (typeof sourceFile === 'string') {
      _sourceFiles.push(sourceFile);
    }

    const commandPrefix = _sourceFiles.reduce((prefix, _sourceFile) => {
      return `${prefix}source '${_sourceFile}' && `;
    }, '');

    const commandPrefixed = `${commandPrefix} { ${command} ; }`;

    const output = await $({
      uid,
      shell: '/bin/bash',
      all: true,
    })(commandPrefixed);

    return output;

  } catch (error) {
    throw error;
  }
}
export async function variableRead({
  sourceFiles = [],
  sourceFile, // optional to read from environment
  variable, // required, bash variable to read
  uid, // optional to run as another user, see user/regularUserIdGet
 } = {}) {

  try {

    const { stdout } = await sourceAndExecute({
      sourceFiles,
      sourceFile,
      uid,
      command: ` \
        for v in "\${${variable}[@]}" ; do \
          printf "\$v\\0" ; \
        done \
      `,
    });

    if (stdout.length === 0) {
      // '' when no value
      return undefined;
    }

    let values = stdout.split('\0');
    // remove last empty string
    values.pop();

    if (values.length === 1) {
      return values[0];
    }

    return values;

  } catch (error) {
    throw error;
  }

}

// this handles '~', '$HOME', and other bash expansions
export async function pathResolve({
  uid,
  path,
  sourceFiles = [],
  sourceFile, // optional to read from environment
} = {
}) {
  const { stdout } = await sourceAndExecute({
    uid,
    sourceFiles,
    sourceFile,
    command: `echo ${path}`,
  });

  return nodePath.resolve(stdout);
}
