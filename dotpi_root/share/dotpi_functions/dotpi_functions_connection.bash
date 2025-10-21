#!/bin/bash

_dotpi_connection_get_options() {

  _echo_empty_option_error() {
    dotpi_echo_error "$1 requires a non-empty option argument."
  }

  # From http://mywiki.wooledge.org/BashFAQ/035

  while true ; do
    case $1 in

      -h|-\?|--help)
        _dotpi_usage    # Display a usage synopsis.
        return 0
        ;;

      -f|--file)       # Takes an option argument; ensure it has been specified.
        if [ -z "$2" ] ; then
            _dotpi_usage
            _echo_empty_option_error "$1"
            return 1
        else
            file="$2"
            shift
        fi
        ;;

      -k|--key)
        if [ -z "$2" ] ; then
            _dotpi_usage
            _echo_empty_option_error "$1"
            return 1
        else
            key="$2"
            shift
        fi
        ;;

      -v|--value)
        if [ -z "$2" ] ; then
            _dotpi_usage
            _echo_empty_option_error "$1"
            return 1
        else
            value="$2"
            shift
        fi
        ;;

      -i|--id)
        if [ -z "$2" ] ; then
            _dotpi_usage
            _echo_empty_option_error "$1"
            return 1
        else
            id="$2"
            shift
        fi
        ;;


      --)              # End of all options.
        shift
        break
        ;;

      -?*) # Unknown
        _dotpi_usage
        dotpi_echo_error "Unknown option: $1"
        return 1
        ;;

      *)               # Default case: No more options, so break out of the loop.
        break

    esac

    shift
  done

}

# write key value pair to an .nmconnection file
dotpi_connection_write() (
  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} [--file <file>] --key <key> --value <value>"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  file=
  key=
  value=
  if ! _dotpi_connection_get_options "${@}" ; then
      return $?
  fi

  if [ -z "$key" ] ; then
      _dotpi_usage
      dotpi_echo_error "missing key option"
      return 1
  fi

  if [ -z "$value" ] ; then
      _dotpi_usage
      dotpi_echo_error "missing value option"
      return 1
  fi

  if [ -z "$file" ] ; then
      dotpi_echo_error "missing file option"
      return 1
  fi

  git config --file "$file" "$key" "$value"

  return $?
)

# read a value corresponding to a key in an .nmconnection file
dotpi_connection_read() (
  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} [--file <file>] --key <key>"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  file=
  key=
  value=
  id=
  if ! _dotpi_connection_get_options "${@}" ; then
      return $?
  fi

  if [ -z "$key" ] ; then
      _dotpi_usage
      dotpi_echo_error "missing key option"
      return 1
  fi

  if [ -z "$file" ] ; then
      _dotpi_usage
      dotpi_echo_error "missing file option"
      return 1
  fi

  if ! [ -r "$file" ] ; then
      _dotpi_usage
      dotpi_echo_error "file ${file} is not readable"
      return 1
  fi

  # use printf to unquote strings
  value="$(git config --file "$file" "$key")"
  printf '%s\n' "$value"

  return $?
)

# delete a key in an .nmconnection file
dotpi_connection_delete() (
  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} [--file <file>] --key <key>"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  file=
  key=
  value=
  id=
  if ! _dotpi_connection_get_options "${@}" ; then
      return $?
  fi

  if [ -z "$key" ] ; then
      _dotpi_usage
      dotpi_echo_error "missing key option"
      return 1
  fi

  if [ -z "$file" ] ; then
      _dotpi_usage
      dotpi_echo_error "missing value option"
      return 1
  fi

  if ! [ -r "$file" ] ; then
      _dotpi_usage
      dotpi_echo_error "file ${file} is not readable"
      return 1
  fi

  git config --file "$file" --unset "$key"

  return $?
)

dotpi_connections_update() (
  if [[ "$USER" != "root" ]]; then
    dotpi_echo_error "This command must be run as root"
    return 1
  fi

  source_path="${DOTPI_ROOT}/etc/network"
  destination_path='/etc/NetworkManager/system-connections'
  mkdir -p -- "$destination_path"

  # instantiate nmconnection templates
  while IFS= read -r -d '' f ; do
    destination_filename="$(basename -- "${f%.template}")"
    dotpi envsubst < "$f" > "${destination_path}/${destination_filename}"
  done < <(find "${source_path}" -name '*.nmconnection.template' -print0)

  # copy regular nmconnection files
  while IFS= read -r -d '' f ; do
    destination_filename="$(basename -- "${f}")"
    cp --force -- "$f" "${destination_path}/${destination_filename}"
  done < <(find "${source_path}" -name '*.nmconnection' -print0)

  # NetworkManager requires secure permissions
  chmod 'u=rw,go=' "${destination_path}"/*
  chown -R root:root "${destination_path}"
)

dotpi_connection_ap_id_get() (

  connections_path="${DOTPI_ROOT}/etc/network"

  while IFS= read -r -d '' f ; do
    section='connection'
    connection_type="$(dotpi_connection_read --file "$f" --key "${section}.type")"
    if [[ "$connection_type" != 'wifi' && "$connection_type" != '802-11-wireless' ]] ; then
      continue
    fi
    connection_id="$(dotpi_connection_read --file "$f" --key "${section}.id")"


    for section in 'wifi' '802-11-wireless' ; do
      wifi_mode="$(dotpi_connection_read --file "$f" --key "${section}.mode")"
      if [[ "$wifi_mode" == 'ap' ]] ; then
        break
      fi
    done

    if [[ "$wifi_mode" != 'ap' ]] ; then
      continue
    fi

    echo "$connection_id"
    return 0

  done < <(find "${connections_path}" -name '*.nmconnection*' -print0)
)

dotpi_connection_ap_activate() (
  if [[ "$USER" != "root" ]]; then
    dotpi_echo_error "This command must be run as root"
    return 1
  fi

  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} [--id <connection.id>]"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  file=
  key=
  value=
  id=
  if ! _dotpi_connection_get_options "${@}" ; then
      return $?
  fi

  if [ -z "$id" ] ; then
      dotpi_echo_warning "Missing id option, using first access point connection"
      id="$(dotpi_connection_ap_id_get)"
      if [ -z "$id" ] ; then
          dotpi_echo_error "No access point connection found"
          return 1
      fi
  fi

  connections_path="${DOTPI_ROOT}/etc/network"

  # first, activate the requested access point
  while IFS= read -r -d '' f ; do
    section='connection'

    connection_id="$(dotpi_connection_read --file "$f" --key "${section}.id")"
    if [[ "$connection_id" != "$id" ]] ; then
      continue
    fi

    connection_type="$(dotpi_connection_read --file "$f" --key "${section}.type")"
    if [[ "$connection_type" != 'wifi' && "$connection_type" != '802-11-wireless' ]] ; then
      continue
    fi

    for section in 'wifi' '802-11-wireless' ; do
      wifi_mode="$(dotpi_connection_read --file "$f" --key "${section}.mode")"
      if [[ "$wifi_mode" == 'ap' ]] ; then
        break
      fi
    done

    if [[ "$wifi_mode" != 'ap' ]] ; then
      continue
    fi

    dotpi_echo_info "Activating connection id: ${connection_id}"
    connection_autoconnect='true'
    dotpi_connection_write --file "$f" --key 'connection.autoconnect' \
      --value "$connection_autoconnect"

    break

  done < <(find "${connections_path}" -name '*.nmconnection*' -print0)

  if [[ "$connection_id" != "$id" ]] ; then
    dotpi_echo_error "Access point connection id ${id} not found"
    return 1
  fi

  if [[ "$wifi_mode" != 'ap' ]] ; then
    dotpi_echo_error "Connection id ${id} is not an access point"
    return 1
  fi

  # then, on success only, deactivate other access points
  while IFS= read -r -d '' f ; do
    section='connection'

    connection_id="$(dotpi_connection_read --file "$f" --key "${section}.id")"
    if [[ "$connection_id" == "$id" ]] ; then
      continue
    fi

    connection_type="$(dotpi_connection_read --file "$f" --key "${section}.type")"
    if [[ "$connection_type" != 'wifi' && "$connection_type" != '802-11-wireless' ]] ; then
      continue
    fi

    dotpi_echo_info "Deactivating connection id: ${connection_id}"
    connection_autoconnect='false'
    dotpi_connection_write --file "$f" --key 'connection.autoconnect' \
      --value "$connection_autoconnect"

  done < <(find "${connections_path}" -name '*.nmconnection*' -print0)

  dotpi_connections_update
  systemctl restart NetworkManager.service || {
    return_code=$?
    dotpi echo_error "error while restarting NetworkManager.service: ${return_code}"
    return "${return_code}"
  }
)


dotpi_connection_ap_deactivate() (
  if [[ "$USER" != "root" ]]; then
    dotpi_echo_error "This command must be run as root"
    return 1
  fi

  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command}"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  file=
  key=
  value=
  id=
  if ! _dotpi_connection_get_options "${@}" ; then
      return $?
  fi

  if [[ "$id" != '' ]] ; then
      dotpi_echo_error "id option is not valid for deactivating all access points"
      return 1
  fi

  connections_path="${DOTPI_ROOT}/etc/network"

  # first, deactivate access point
  while IFS= read -r -d '' f ; do
    section='connection'
    connection_id="$(dotpi_connection_read --file "$f" --key "${section}.id")"
    connection_type="$(dotpi_connection_read --file "$f" --key "${section}.type")"
    if [[ "$connection_type" != 'wifi' && "$connection_type" != '802-11-wireless' ]] ; then
      continue
    fi

    for section in 'wifi' '802-11-wireless' ; do
      wifi_mode="$(dotpi_connection_read --file "$f" --key "${section}.mode")"
      if [[ "$wifi_mode" == 'ap' ]] ; then
        break
      fi
    done

    if [[ "$wifi_mode" == 'ap' ]] ; then
      dotpi_echo_info "Deactivating connection id: ${connection_id}"
      connection_autoconnect='false'
      dotpi_connection_write --file "$f" --key 'connection.autoconnect' --value 'false'

    else
      dotpi_echo_info "Activating connection id: ${connection_id}"
      connection_autoconnect='false'
      dotpi_connection_write --file "$f" --key 'connection.autoconnect' --value 'true'
    fi


  done < <(find "${connections_path}" -name '*.nmconnection*' -print0)

  dotpi_connections_update
  systemctl restart NetworkManager.service || {
    return_code=$?
    dotpi echo_error "error while restarting NetworkManager.service: ${return_code}"
    return "${return_code}"
  }

)
