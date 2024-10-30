import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const LIB_ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
export const CWD = process.cwd();

// shell scripts that we need to execute
export const PATH_DOTPI_INIT_BASH = path.join(LIB_ROOT, 'dotpi_root/share/dotpi_init.bash');
export const PATH_DOTPI_PREPARE_SD_CARD_BASH = path.join(LIB_ROOT, 'dotpi_root/bin/dotpi_prepare_sd_card');
// directories to read from and write to, repsectively
export const PATH_TEMPLATE_DIRECTORY = path.join(LIB_ROOT, 'src/templates');

// the files / directories that define a project
export const PATH_DOTPI_PROJECT_BASH = 'dotpi_project.bash';
export const PATH_DOTPI_SECRETS_BASH = 'dotpi_secrets.bash';
export const PATH_SSH_DIRECTORY = 'ssh';
export const PATH_NETWORK_DIRECTORY = 'network';
export const PATH_GITIGNORE = '.gitignore';
export const PATH_README = 'README.md';
export const PATH_DOTPI_FILE = '.dotpi';
// these ones are within a project, e.g. where the next instance number is stored
export const PATH_DOTPI_TMP_DIRECTORY = 'tmp';
export const PATH_DOTPI_TMP_BASH = path.join(PATH_DOTPI_TMP_DIRECTORY, 'dotpi_tmp.bash');

// misc
export const DOTPI_SSH_KEYS_PREFIX = 'id_rsa';
export const PROJECT_NAME_REGEXP = /^[a-z0-9\-_]+$/;
export const WIFI_ID_REGEXP = PROJECT_NAME_REGEXP;