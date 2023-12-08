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
  prepend_line_if_new=
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
  prepend_line_if_new=
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
  printf "$value\n"

  return $?
)

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
  prepend_line_if_new=
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

