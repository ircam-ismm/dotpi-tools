#!/bin/bash

# when sourced, the shell might not be bash
if [ -n "$ZSH_VERSION" ] ; then
  _local_file="${0:a}"
elif [ -n "$BASH_VERSION" ] ; then
  _local_file="${BASH_SOURCE[0]}"
else
    _local_file="$0"
fi
_local_path="$(cd -- "$(dirname -- "${_local_file}")" && pwd)"

DOTPI_ROOT="$(cd -- "${_local_path}/.." && pwd)"
export DOTPI_ROOT

export PATH="${PATH}:${DOTPI_ROOT}/usr/bin"
export PATH="${PATH}:${DOTPI_ROOT}/bin"

source "${DOTPI_ROOT}/share/dotpi_functions.bash"

source "${DOTPI_ROOT}/share/dotpi_environment.bash"
