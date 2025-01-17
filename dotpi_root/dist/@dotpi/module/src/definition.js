
import { $ } from 'execa';

export async function definitionGet(module) {
  const { stdout } = await $`npm view --json -- ${module}`;
  return JSON.parse(stdout);
}
