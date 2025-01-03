import{ $ } from 'execa';

import { regularUserIdGet } from './user.js';

const dotpiRootDefault = '/opt/dotpi';
const shell = '/bin/bash';

export async function dotpiRootGet() {
  let dotpiRoot = process.env.DOTPI_ROOT;
  if (!dotpiRoot) {

    const id = regularUserIdGet();
    ({ stdout: dotpiRoot} = await $({id, shell })`echo $DOTPI_ROOT`);

    if (!dotpiRoot) {
      dotpiRoot=dotpiRootDefault;
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
