#!/bin/bash

dotpi_apt_get() {
  # fully automated, with default choices (yes to any questions)
  # keep installation explicit, do not install recommended

  # wait for other apt-get processes (first or daily updates)
  # -1 is unlimited
  # DPkg::Lock::Timeout=-1

  # wait for distant resources (internet)
  # -1 is unlimited
  # Acquire::Retries=-1

  DEBIAN_FRONTEND=noninteractive \
                 apt-get \
                 -o APT::Get::Assume-Yes=true \
                 -o APT::Install-Recommends=false \
                 -o APT::Install-Suggests=false \
                 -o DPkg::Lock::Timeout=-1 \
                 -o Acquire::Retries=-1 \
                 -o Acquire::Check-Valid-Until=false \
                 -o Acquire::Check-Date=false \
                 "${@}"
}

dotpi_source_if_available() {
  if [ -f "$1" ] && [ -r "$1" ] ; then
      source "$1"
      return 0
  else
      return 1
  fi
}

# `readlink -f` is not available for MacOS
# https://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac
dotpi_readlink_follow() (
  target_file="$1"

  cd -- "$(dirname -- "$target_file")" || {
    echo ''
    return 1
  }
  target_file="$(basename -- "$target_file")"

  # Iterate down a (possible) chain of symlinks
  while [[ -L "$target_file" ]] ; do
    target_file="$(readlink -- "$target_file")"
    cd -- "$(dirname -- "$target_file")" || {
      echo ''
      return 1
    }
    target_file="$(basename -- "$target_file")"
  done

  # Compute the canonicalized name by finding the physical path
  # for the directory we're in and appending the target file.
  target_path="$(pwd -P)"
  result="${target_path}/${target_file}"
  echo "$result"
)

# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37

dotpi_color_none='\e[0m'
dotpi_color_red='\e[0;31m'
dotpi_color_orange='\e[0;33m'
dotpi_color_green='\e[0;32m'

dotpi_echo_error() {
  printf "${dotpi_color_red}ERROR: ${dotpi_color_none}${*}\n" >&2
}

dotpi_echo_warning() {
  printf "${dotpi_color_orange}WARNING: ${dotpi_color_none}${*}\n" >&2
}

dotpi_echo_info() {
  printf "${dotpi_color_green}INFO: ${dotpi_color_none}${*}\n" >&2
}


# remove colour and other control sequences
# Cf. https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream
dotpi_colour_remove() {
  dotpi_sed 's/\e\[[0-9;]*[mGKH]//g'
}

dotpi_log() (
  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: <command> 2>&1 | ${_dotpi_command} <log_file>" >&2
  }

  log_file="$1"
  if [[ -z "$log_file" ]] ; then
      dotpi_echo_error "missing output filename"
      _dotpi_usage
      return 1
  fi


  tee -i >(while IFS= read -r line; do
             echo "$line" \
                 | dotpi_colour_remove \
                 | dotpi_sed "s/^/$(date '+%Y-%m-%d %H:%M:%S') /" \
                             >> "$log_file"
           done)
)

dotpi_sed() {
  # sed is not portable
  perl -pe "$@"
  return $?
}

# dotpi_uuidgen
if $( command -v uuidgen > /dev/null ) ; then
    dotpi_uuidgen() {
      uuidgen | tr '[:upper:]' '[:lower:]'
    }
elif [ -r /proc/sys/kernel/random/uuid ] ; then
    dotpi_uuidgen() {
      cat /proc/sys/kernel/random/uuid
    }
else
    dotpi_uuidgen() {
      printf '%08x-%04x-%04x-%012x\n' $(( (RANDOM << 16 + RANDOM) % 0xffffffff )) $(( RANDOM )) $(( RANDOM )) $(( ( (RANDOM << 16 + RANDOM) << 16) + RANDOM % 0xffffffffffff ))
    }
fi

dotpi_file_word_size() {
  if [[ $# != 1 ]] ; then
      dotpi_echo_error 'First argument is file to read'
      dotpi_echo_error "Usage: ${FUNCNAME[0]} <file_to_read>"
      return 1
  fi

  echo "$(file "$1" | perl -pe 's/.*(32|64)-bit.*/$1/' )"
}

# requires ts form moretuils
dotpi_timestamp() {
  # [now (time_from_start)]
  ts -s '(%H:%M:%.S)]' | ts '[%Y-%m-%d %H:%M:%S'
}
