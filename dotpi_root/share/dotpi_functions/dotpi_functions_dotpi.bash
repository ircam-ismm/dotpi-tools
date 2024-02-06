#!/bin/bash

dotpi_dotpi_update() (
  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  log_file="${DOTPI_ROOT}/var/log/${_dotpi_command}_$(date +"%Y%m%d-%H%M%S").log"
  exec &> >(dotpi log "$log_file")

  dotpi echo_info "Log of dotpi update: ${log_file}"

  src_path="${DOTPI_ROOT}/tmp"

  cd -- "${src_path}" || {
    dotpi_echo_error "${_dotpi_command}: could not change directory to runtime: ${src_path}"
    return 1
  }

  # clone without history, without any file
  src_name="dotpi-install"
  src_path="${src_path}/${src_name}"
  rm -rf "${src_path}"
  git clone -n --depth=1 --filter=tree:0 -b main "https://github.com/ircam-ismm/${src_name}.git"

  cd "${src_path}" || {
    dotpi_echo_error "${_dotpi_command}: could not change directory to runtime: ${src_path}"
    return 1
  }

  src_root_name="dotpi_root"
  # checkout only dotpi-root
  git sparse-checkout set --no-cone "${src_root_name}"
  # actual checkout
  git checkout

  dotpi echo_info "Update dotpi from sources"
  tar c -C "${src_root_name}" '.' | tar xv -m --no-same-owner --no-same-permissions --no-overwrite-dir -C "${DOTPI_ROOT}"
)
