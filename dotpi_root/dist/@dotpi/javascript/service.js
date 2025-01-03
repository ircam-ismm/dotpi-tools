import { $ } from 'execa';

export async function install({
  user = false,
  file,
} = {}) {
  if (process.getuid() !== 0) {
    // even a user service must be installed by root
    throw new Error('Only the root user can install a service');
  }

  try {
    const output = await $({
      shell: '/bin/bash', // for dotpi environment
      env: { FORCE_COLOR: 'true' }, // do not remove colors
      all: true, // interleave stdout and stderr
    })`dotpi service-install ${user ? '--user' : ''} ${file}`;

    return output;

  } catch (error) {
    throw error;
  }

}

export async function uninstall({
  user = false,
  name,
} = {}) {
  if (process.getuid() !== 0) {
    // even a user service must be installed by root
    throw new Error('Only the root user can uninstall a service');
  }

  try {
    const output = await $({
      shell: '/bin/bash', // for dotpi environment
      env: { FORCE_COLOR: 'true' }, // do not remove colors
      all: true, // interleave stdout and stderr
    })`dotpi service-uninstall ${user ? '--user' : ''} ${name}`;

    return output;

  } catch (error) {
    throw error;
  }

}
