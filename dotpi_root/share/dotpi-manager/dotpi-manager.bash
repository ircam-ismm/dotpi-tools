#!/bin/bash

# source this file to add functions to the dotpi environment

dotpi_manager_update() (
  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  log_file="${DOTPI_ROOT}/var/log/${_dotpi_command}_$(date +"%Y%m%d-%H%M%S").log"
  exec &> >(dotpi log "$log_file")

  dotpi echo_info "Log of dotpi-manager update: ${log_file}"

  destination="${DOTPI_ROOT}/share/dotpi-manager/runtime"
  cd -- "$destination" || {
    dotpi_echo_error "dotpi-manager: could not change directory to runtime: ${destination}"
    return 1
  }

  service_name='dotpi-manager.service'

  command_prefix=(systemctl --user --machine="${SUDO_USER}@")

  "${command_prefix[@]}" stop "${service_name}"

  git pull origin main
  rm -rf node_modules
  npm install --omit=dev --loglevel verbose

  "${command_prefix[@]}" start "${service_name}"
)
