import fs from 'node:fs/promises';
import{ $ } from 'execa';

import { regularUserIdGet } from './user.js';
import { readVariable } from './bash.js';

const dotpiRootDefault = '/opt/dotpi';
const shell = '/bin/bash';

export async function dotpiRootGet() {

  let dotpiRoot = process.env.DOTPI_ROOT;
  if (!dotpiRoot) {
    const uid = regularUserIdGet();
    dotpiRoot = await readVariable({ uid, variable: 'DOTPI_ROOT' });
  }

  if (!dotpiRoot) {
    try {
      await fs.access(dotpiRootDefault);
      dotpiRoot = dotpiRootDefault;
    } catch (error) {
      throw new Error(`DOTPI_ROOT not set and ${dotpiRootDefault} not found`);
    }
  }

  return dotpiRoot;
}

export async function isRaspberryPi() {
  try {
    const output = await $`dotpi system_is_raspberry_pi`;
    return output.exitCode === 0;
  } catch (error) {
    return false;
  }
}
