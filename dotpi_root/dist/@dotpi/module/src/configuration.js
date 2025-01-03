import fs from 'node:fs/promises';
import path from 'node:path';

import * as echo from '@dotpi/javascript/echo.js';
import { dotpiRootGet } from '@dotpi/javascript/system.js';

export async function configurationGet() {

  let dotpiRoot;
  let modulesPath;
  let modulesConfiguration;
  try {
    dotpiRoot = await dotpiRootGet();
    modulesPath = path.join(dotpiRoot, 'lib');
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
