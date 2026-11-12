import { createRequire } from 'node:module';
import path from 'node:path';

// Resolve pnpm's package.json, then read its "bin" entry
// require.resolve('pnpm') returns the package.json path in both v11 and v12
const require = createRequire(import.meta.url);
const pnpmPackagePath = require.resolve('pnpm');
const pnpmPackage = require(pnpmPackagePath);
const pnpmExecutableRelativePath = (typeof pnpmPackage.bin === 'string'
  ? pnpmPackage.bin
  : pnpmPackage.bin.pnpm
);

export const pnpmExecutable = path.join(
  path.dirname(pnpmPackagePath),
  pnpmExecutableRelativePath,
);
