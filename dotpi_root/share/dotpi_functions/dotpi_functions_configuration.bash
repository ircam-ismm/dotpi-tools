#!/bin/bash

_dotpi_configuration_get_options() {

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

      -p|--prefix)
        if [ -z "$2" ] ; then
          _dotpi_usage
          _echo_empty_option_error "$1"
          return 1
        else
          prefix="$2"
          shift
        fi
        ;;

      -N|--prepend-line-if-new)
        if [ -z "$2" ] ; then
          _dotpi_usage
          _echo_empty_option_error "$1"
          return 1
        else
          prepend_line_if_new="$2"
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

dotpi_configuration_escape_string() (
  # escape / \ $
  echo "$(echo "$1" | perl -pe 's#([/\\\$])#\\${1}#g')"
)

dotpi_configuration_get_pattern() (
  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} --key <key>"
    echo "Usage: ${_dotpi_command} --prefix <prefix>"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  key=
  if ! _dotpi_configuration_get_options "${@}" ; then
      return $?
  fi

  if [ -z "$key" ] && [ -z "$prefix" ] ; then
      _dotpi_usage
      dotpi_echo_error "key or prefix is required"
      return 1
  fi


  if [ -n "$key" ] ; then
        # [<leading>] <key> <assignment> <value> [ <values>] [<trailing>]

        # start of line, and spaces
        # invert for no comment, no non-spaces
        _dotpi_configuration_pattern_leading='(^[^#\S]*)'

        # escape
        key_escaped="$(dotpi_configuration_escape_string "$key")"
        # group and disable pattern metacharacters
        _dotpi_configuration_pattern_key="(${key_escaped})"

        # = with surrounding spaces
        _dotpi_configuration_pattern_assignment='(\s*=\s*)'

        # value is a repetition of non-space characters
        # invert for no comment, no space
        _dotpi_configuration_pattern_value='([^#\s]+)'

        # optional value containing spaces (terminated with a non-space)
        _dotpi_configuration_pattern_value_with_spaces='((\s+[^#\s]+)*)'

        # trailing spaces and trailing comments until the end of line
        # (including the end of line)
        _dotpi_configuration_pattern_trailing='(\s*#?.*$)'

        echo "\
$_dotpi_configuration_pattern_leading\
$_dotpi_configuration_pattern_key\
$_dotpi_configuration_pattern_assignment\
$_dotpi_configuration_pattern_value\
$_dotpi_configuration_pattern_value_with_spaces\
$_dotpi_configuration_pattern_trailing\
"
  elif [ -n "$prefix" ] ; then
        # [<leading>] <prefix> [<trailing>]

        # start of line, and spaces
        # invert for no comment, no non-spaces
        _dotpi_configuration_pattern_leading='(^[^#\S]*)'

        # escape
        prefix_escaped="$(dotpi_configuration_escape_string "$prefix")"
        # group and disable pattern metacharacters
        _dotpi_configuration_pattern_prefix="(${prefix_escaped})"

        # anything until the end of line
        # (including the end of line)
        _dotpi_configuration_pattern_trailing='(.*$)'

        echo "\
$_dotpi_configuration_pattern_leading\
$_dotpi_configuration_pattern_prefix\
$_dotpi_configuration_pattern_trailing\
"

  fi

        return 0
)

dotpi_configuration_comment() (
  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} [--file <file>] --key <key>"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  file=
  key=
  if ! _dotpi_configuration_get_options "${@}" ; then
      return $?
  fi

  if [ -z "$key" ] ; then
      _dotpi_usage
      dotpi_echo_error "missing key option"
      return 1
  fi

  perl_options=()
  if [ -n "$file" ] ; then
      perl_options+=( '-i' "$file" )
  fi

  pattern="$(dotpi_configuration_get_pattern --key "$key")"
  # keep leading spaces, and trailing (including end of line)
  perl -pe "s/${pattern}/"'${1}# ${2}${3}${4}${5}${7}/' "${perl_options[@]}"
  return $?
)

dotpi_configuration_write() (
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
  if ! _dotpi_configuration_get_options "${@}" ; then
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

  if [ -n "$file" ] ; then
      if ! [ -r "$file" ] ; then
          touch "$file"
      fi
  else
      input_file='/dev/stdin'
      output_file='/dev/stdout'
  fi

  pattern="$(dotpi_configuration_get_pattern --key "$key")"
  value_escaped="$(dotpi_configuration_escape_string "$value")"
  # trailing includes the end of line
  perl_command=('perl' '-pe' "s/${pattern}/"'${1}${2}${3}'"${value_escaped}"'${7}/')

  find_command=('dotpi_configuration_find' '--key' "$key")

  if [ -n "$file" ] ; then
      "${perl_command[@]}" -i -- "$file"
      found=$( "${find_command[@]}" --file "$file" )
      output_file="$file"
  else
      # duplicate stdout
      "${perl_command[@]}" 3>&1 ; found=$( "${find_command[@]}" <3 )
  fi

  if (( found == 0 )) ; then
      # add a new line in case file does not already end with one
      echo '' >> "$output_file"
      if [ -n "$prepend_line_if_new" ] ; then
          echo "$prepend_line_if_new" >> "$output_file"
      fi
      echo "${key}=${value_escaped}" >> "$output_file"
  fi


  return $?
)

dotpi_configuration_read() (
  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} [--file <file>] --key <key>"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  file=
  key=
  if ! _dotpi_configuration_get_options "${@}" ; then
      return $?
  fi

  if [ -z "$key" ] ; then
      _dotpi_usage
      dotpi_echo_error "missing key option"
      return 1
  fi

  perl_options=()
  if [ -n "$file" ] ; then
      if ! [ -r "$file" ] ; then
          dotpi_echo_error "${file} is not readable"
          return 1 # false
      fi

      perl_options+=( "$file" )
  fi

  pattern="$(dotpi_configuration_get_pattern --key "$key")"

  values=()
  # split values with new line, keep spaces
  while IFS= read -r line ; do
    values+=("$line")
  done < <(perl -ne 'if (m/'"$pattern"'/) { print "${4}${5}\n" }' "${perl_options[@]}" )

  if (( ${#values} == 0 )) ; then
      return 1 # false
  else
      # last instance
      echo "${values[@]: -1}"
      return 0 # true
  fi
)

dotpi_configuration_find() (
  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} [--file <file>] --key <key>"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  file=
  key=
  if ! _dotpi_configuration_get_options "${@}" ; then
      return $?
  fi

  if [ -z "$key" ] ; then
      _dotpi_usage
      dotpi_echo_error "missing key option"
      return 1
  fi

  read_options=()
  if [ -n "$file" ] ; then
      read_options+=( '--file' "$file" )
  fi

  dotpi_configuration_read --key "$key" "${read_options[@]}" > /dev/null
  return_value=$?
  # 0 is true
  echo $(( !return_value ))
  return $return_value
)

dotpi_configuration_delete() (
  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} [--file <file>] --key <key>"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  file=
  key=
  if ! _dotpi_configuration_get_options "${@}" ; then
      return $?
  fi

  if [ -z "$key" ] ; then
      _dotpi_usage
      dotpi_echo_error "missing key option"
      return 1
  fi

  perl_options=()

  if [ -n "$file" ] ; then
      if ! [ -r "$file" ] ; then
          dotpi_echo_error "${file} is not readable"
          return 1 # false
      fi

      perl_options+=( '-i' "$file" )
  fi

  pattern="$(dotpi_configuration_get_pattern --key "$key")"

  perl -ne 'if (! m/'"${pattern}"'/) { print "$_" }' "${perl_options[@]}"

  return $?
)

dotpi_configuration_replace_region() {
  command_name="${FUNCNAME[0]}"
  if (( ${#} < 3 )) ; then
      echo "Usage: ${command_name} <start_string> <end_string> <substitution> [<file>]"
      dotpi_echo_error "${command_name} needs at least 3 arguments"
      return 1
  fi


  local start="$(dotpi_configuration_escape_string "$1")"
  local end="$(dotpi_configuration_escape_string "$2")"
  local substitution="$(dotpi_configuration_escape_string "$3")"
  local file="$4"

  local perl_options=()
  if [ -n "$file" ] ; then
      perl_options+=( '-i' "$file" )
  fi

  perl -p0e 's/'"$start"'.*?'"$end"'/'"$substitution"'/smg' "${perl_options[@]}"

  return $?
}
