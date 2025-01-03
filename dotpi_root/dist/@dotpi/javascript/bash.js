import fs from 'node:fs/promises';
import{ $ } from 'execa';

import { regularUserIdGet } from './user.js';

export async function readVariable({
  filename = '/dev/null', // to get variable from environment
  variable,
  uid = regularUserIdGet(),
 } = {}) {

  try {

    // check if file exists
    await fs.access(filename);

    const { stdout } = await $({
      uid,
      shell: '/bin/bash',
    })`
    source '${filename}' && { \
      for v in "\${${variable}[@]}" ; do \
        printf "\$v\\0" ; \
      done ; \
    }`;

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
    if (error.code === 'ENOENT') {
      throw new Error(`File not found: ${filename}`);
    }

    if (error.stderr) {
      throw new Error(error.stderr);
    }

    throw error;
  }

}
