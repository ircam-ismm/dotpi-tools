import fs from 'node:fs/promises';
import path from 'node:path';

import { dotpiRootGet } from '@dotpi/javascript/system.js';
import * as echo from '@dotpi/javascript/echo.js';

export async function dotpiConfigurationGet({
  dotpiRoot,
  prefix,
} = {}) {
  dotpiRoot ??= await dotpiRootGet();

  let modulesPath;
  let modulesConfiguration;
  try {

    modulesPath = (prefix ? prefix : path.join(dotpiRoot, 'lib'));
    modulesConfiguration = JSON.parse(
      await fs.readFile(
       path.join(dotpiRoot, 'etc', 'dotpi_modules.json')
      )
    );

    return {
      dotpiRoot,
      modulesPath,
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
