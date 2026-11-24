#!/bin/bash

dotpi_regular_user_get_id() (
  # 1000 is the default user id for the first user on a Raspberry Pi OS system
  regular_user_id="${SUDO_UID:-1000}"
  if (( regular_user_id == 0 )) ; then
    regular_user_id=1000
  fi

  echo "$regular_user_id"
)

dotpi_regular_user_get_name() (
  regular_user_id="$(dotpi_regular_user_get_id)"
  regular_user_name="$(getent passwd "$regular_user_id" | cut -d: -f1)"
  echo "$regular_user_name"
)

dotpi_regular_user_get_gid() (
  regular_user_id="$(dotpi_regular_user_get_id)"
  regular_user_name="$(getent passwd "$regular_user_id" | cut -d: -f3)"
  echo "$regular_user_name"
)

dotpi_regular_user_get_home() (
  regular_user_id="$(dotpi_regular_user_get_id)"
  regular_user_home="$(getent passwd "$regular_user_id" | cut -d: -f6)"
  echo "$regular_user_home"
)

dotpi_regular_user_run() (
  if [[ "$USER" == "root" ]]; then
    regular_user="$(dotpi_regular_user_get_name)"
    sudo systemd-run --quiet --pipe --wait --collect --machine="${regular_user}@" --user -- /bin/bash -c '"$@"' - "$@"
  else
    "$@"
  fi
)
