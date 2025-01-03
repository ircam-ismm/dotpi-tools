import { $ } from 'execa';

export const firstUserID = 1000;
const regularUserIdDefault = firstUserID;

export function regularUserIdGet() {
  let regularUserId = process.env.SUDO_UID;
  if (!regularUserId) {
    regularUserId = regularUserIdDefault;
  }

  return regularUserId;
}

export async function regularUserGet() {
  const { stdout } = await $`getent passwd ${regularUserIdGet()}`;

  return {
    name: stdout.split(':')[0],
    uid: stdout.split(':')[2],
    gid: stdout.split(':')[3],
    home: stdout.split(':')[5],
    shell: stdout.split(':')[6],
  };
}
