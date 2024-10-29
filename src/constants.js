import { join } from 'path';

// shell scripts that we need to execute
export const PATH_DOTPI_INIT_BASH = 'dotpi_root/share/dotpi_init.bash';
export const PATH_DOTPI_PREPARE_SD_CARD_BASH = 'dotpi_root/bin/dotpi_prepare_sd_card';
// these ones are within a project, e.g. where the next instance number is stored
export const PATH_DOTPI_TMP_DIRECTORY = 'tmp';
export const PATH_DOTPI_TMP_BASH = join(PATH_DOTPI_TMP_DIRECTORY, 'dotpi_tmp.bash');

// directories to read from and write to, repsectively
export const PATH_TEMPLATE_DIRECTORY = 'src/templates';
export const PATH_PROJECTS_DIRECTORY = 'projects';

// the files / directories that define a project
export const PATH_DOTPI_PROJECT_BASH = 'configuration/dotpi_project.bash';
export const PATH_DOTPI_SECRETS_BASH = 'secrets/dotpi_secrets.bash';
export const PATH_SSH_DIRECTORY = 'secrets/ssh';
export const PATH_NETWORK_DIRECTORY = 'secrets/network';
export const PATH_GITIGNORE = '.gitignore';
export const PATH_README = 'README.md';

// misc
export const DOTPI_SSH_KEYS_PREFIX = 'id_rsa';
export const PROJECT_NAME_REGEXP = /^[a-z0-9\-_]+$/;
export const WIFI_ID_REGEXP = PROJECT_NAME_REGEXP;