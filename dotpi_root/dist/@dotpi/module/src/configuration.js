import fs from 'node:fs/promises';
import path from 'node:path';

import { dotpiRootGet } from '@dotpi/javascript/system.js';
import * as echo from '@dotpi/javascript/echo.js';

export async function dotpiConfigurationGet({
  dotpiRoot,
  prefix,
} = {}) {
  dotpiRoot ??= await dotpiRootGet();

  try {
    const modulesPath = (prefix
      ? path.resolve(prefix)
      : path.resolve(dotpiRoot, 'lib')
    );
    const modulesConfigurationPath = path.resolve(dotpiRoot, 'etc', 'dotpi_modules.json');
    const modulesConfiguration = JSON.parse(
      await fs.readFile(modulesConfigurationPath)
    );

    return {
      dotpiRoot,
      modulesPath,
      modulesConfigurationPath,
      modulesConfiguration,
    };

  } catch (error) {
    echo.error('Error with dotpi configuration:', error.message);
    throw error;
  }
}

export async function moduleConfigurationPathGet({
  module,
  dotpiRoot,
} = {}) {
  dotpiRoot ??= await dotpiRootGet();

  return path.resolve(dotpiRoot, 'etc', module.name);
}
