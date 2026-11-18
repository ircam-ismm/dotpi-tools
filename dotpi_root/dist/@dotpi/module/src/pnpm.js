import { $ } from 'execa';

// pnpm is required for @dotpi/module-module
// It can not installed locally with npm.
// Version 11, needed for 32 bit systems may not respect versions from package.json, and try to upgrade.
// Version 12 breaks on 32 bit systems.

// do not run locally or via npx
export const pnpmExecutable = 'pnpm';

export async function pnpmResolveInPath() {

  try {
    const output = await $`which ${pnpmExecutable}`;
    return output.exitCode === 0;
  } catch (error) {
    return false;
  }

}
