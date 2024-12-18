#!/bin/bash

# Usage: dotpi_service_install [--user] <service_file>
# note: <service_file> is a path
dotpi_service_install() (
  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"

  if (( $# < 1 )); then
    dotpi_echo_info "Usage: ${_dotpi_command} [--user] <service_file>"
    return 1
  fi

  if [[ "$USER" != "root" ]]; then
    dotpi_echo_error "This command must be run as root"
    return 1
  fi

  arguments=("$@")

  # last argument is service file
  service_file="${arguments[-1]}"

  # other arguments are options for systemctl
  # user --user for user services
  command_options=("${arguments[@]}")
  unset "command_options[-1]"

  user_service=0
  for option in "${command_options[@]}"; do
    if [[ "${option}" == "--user" ]]; then
      user_service=1
      break
    fi
  done

  service_name=$(basename -- "${service_file}")

  if (( user_service )); then
    service_destination="/etc/systemd/user"
  else
    service_destination="/etc/systemd/system"
  fi

  ln -s -f "$(dotpi readlink_follow "${service_file}")" "${service_destination}"

  if (( user_service )); then
    regular_user_name="$(dotpi_regular_user_get_name)"

    # drop sudo, with a proper session, including XDG_RUNTIME_DIR and DBUS_SESSION_BUS_ADDRESS
    command_prefix=(systemctl --machine="${regular_user_name}@")
  else
    command_prefix=(systemctl)
  fi

  "${command_prefix[@]}" "${command_options[@]}" daemon-reload

  # be sure to stop as default or previous version might be running
  "${command_prefix[@]}" "${command_options[@]}" stop "${service_name}"
  "${command_prefix[@]}" "${command_options[@]}" enable "${service_name}"
  "${command_prefix[@]}" "${command_options[@]}" start "${service_name}"
)

# Usage: dotpi_service_uninstall [--user] <service_name>
dotpi_service_uninstall() (
  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"

  if (( $# < 1 )); then
    dotpi_echo_info "Usage: ${_dotpi_command} [--user] <service_name>"
    return 1
  fi

  if [[ "$USER" != "root" ]]; then
    dotpi_echo_error "This command must be run as root"
    return 1
  fi

  arguments=("$@")

  # last argument is service file
  service_name="${arguments[-1]}"

  # other arguments are options for systemctl
  # user --user for user services
  command_options=("${arguments[@]}")
  unset "command_options[-1]"

  user_service=0
  for option in "${command_options[@]}"; do
    if [[ "${option}" == "--user" ]]; then
      user_service=1
      break
    fi
  done

  if (( user_service )); then
    service_destination="/etc/systemd/user"
  else
    service_destination="/etc/systemd/system"
  fi

  rm -f "${service_destination}/${service_name}"

  if (( user_service )); then
    regular_user_name="$(dotpi_regular_user_get_name)"

    # drop sudo, with a proper session, including XDG_RUNTIME_DIR and DBUS_SESSION_BUS_ADDRESS
    command_prefix=(systemctl --machine="${regular_user_name}@")
  else
    command_prefix=(systemctl)
  fi

  "${command_prefix[@]}" "${command_options[@]}" stop "${service_name}"
  "${command_prefix[@]}" "${command_options[@]}" disable "${service_name}"
  "${command_prefix[@]}" "${command_options[@]}" daemon-reload
)
