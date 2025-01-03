#!/bin/bash

dotpi_root_get() (
  dotpi_root="${DOTPI_ROOT}"

  if [[ -z "$dotpi_root" ]] ; then
      local_file="$(dotpi_readlink_follow "${BASH_SOURCE[0]}")"
      dotpi_root="$(dirname -- "$(dirname -- "$local_file")")"
  fi

  echo "$dotpi_root"
)

# echo 'raspberry' or 'other'
dotpi_system_is_raspberry_pi() (
  model='other'

  if [ -r /proc/device-tree/model ] ; then
    model="$( (set -o pipefail ; \
cat /proc/device-tree/model \
  | perl -ne '
  if ( m/raspberry/i ) {
    print "raspberry\n"
  } else {
    print "other\n"
  }
  ' ) || echo 'other')"

  fi

  if [[ "$model" == "raspberry" ]] ; then
     return 0
  else
    return 1
  fi
)

dotpi_system_get_bootfs_path() (
  # since Raspberry Pi OS Bookworm
  local_path='/boot/firmware'

  if ! [ -d "$local_path" ] ; then
    # for Raspberry Pi OS Bullseye
    local_path='/boot'

    if ! [ -d "$local_path" ] ; then
      dotpi_echo_error "Boot file-system not found"
      echo ""
      return 1
    fi

  fi

  echo "$local_path"
)

# usage: sudo dotpi system_set_hostname <new_hostname>
dotpi_system_set_hostname() (
  if [ -z "$DOTPI_ROOT" ] ; then
    echo "DOTPI_ROOT undefined" >&2
    return 1
  fi

  if ! dotpi_system_is_raspberry_pi ; then
    dotpi_echo_error "System is not a Raspberry Pi. Not changing hostname"
    return 1
  fi

  if [ -z "$1" ] ; then
     dotpi_echo_error "New hostname argument is required"
    return 1
  fi
  dotpi_instance_hostname="$1"

  destination_file="${DOTPI_ROOT}/etc/dotpi_environment_instance.bash"
  dotpi_configuration_write --file "$destination_file" --key 'dotpi_instance_hostname' --value "$dotpi_instance_hostname"

  hostname_current="$(cat /etc/hostname | tr -d " \t\n\r")"
  if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
    /usr/lib/raspberrypi-sys-mods/imager_custom set_hostname "${dotpi_instance_hostname}"
  else
    echo "${dotpi_instance_hostname}" >/etc/hostname
    sed -i "s/127.0.1.1.*${hostname_current}/127.0.1.1\t${dotpi_instance_hostname}/g" /etc/hosts
  fi

  # explicitly update hostnamectl for immediate effect
  hostnamectl hostname "$dotpi_instance_hostname" || {
    dotpi_echo_warning "hostnamectl unable to change hostname to ${dotpi_instance_hostname}"
  }

  # update services to use the new hostname
  services=(
    'NetworkManager'
    'avahi-daemon.service' # Bonjour / zeroconf / mDNS
  )
  for service in "${services[@]}" ; do
    # restart service only if active (avoid early start on first boot)
    if systemctl is-active "$service" > /dev/null 2>&1 ; then
      systemctl restart "$service" || {
        dotpi_echo_warning "systemctl unable to restart service ${service}"
      }
    fi
  done

)

dotpi_system_execute_on_reboot() (
  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} <user> <executable>"
  }

  user="$1"
  if [[ -z "$user" ]] ; then
    dotpi_echo_error "Missing user argument."
    _dotpi_usage
    exit 1
  fi

  executable="$2"
  if [[ -z "$executable" ]] ; then
    dotpi_echo_error "Missing executable argument."
    _dotpi_usage
    exit 1
  fi

  if ! [[ -d /etc/cron.d ]] ; then
     dotpi_echo_error "System without cron.d support."
     dotpi_echo_error "$1 will NOT execute on next boot."
    return 1
  fi

  executable_name="$(basename "$executable")"
  executable_file="$(dotpi_readlink_follow "$executable")"

  date_string="$(date '+%Y%m%d_%H%M%S')"

  # Cf. https://manpages.debian.org/bookworm/cron/cron.8.en.html

  # As described above, the files under these directories have to pass some
  # sanity checks including the following: be executable, be owned by root, not
  # be writable by group or other and, if symlinks, point to files owned by
  # root. Additionally, the file names must conform to the filename requirements
  # of run-parts: they must be entirely made up of letters, digits and can only
  # contain the special signs underscores ('_') and hyphens ('-'). Any file that
  # does not conform to these requirements will not be executed by
  # run-parts. For example, any file containing dots will be ignored. This is
  # done to prevent cron from running any of the files that are left by the
  # Debian package management system when handling files in /etc/cron.d/ as
  # configuration files (i.e. files ending in .dpkg-dist, .dpkg-orig, .dpkg-old,
  # and .dpkg-new).

  cron_file="/etc/cron.d/zzz_dotpi_${date_string}_$(echo -n "${executable_name}" \
| dotpi_sed 's/[^a-zA-Z0-9_-]/_/g')"

  log_path="${DOTPI_ROOT}/var/log"
  mkdir -p "$log_path"

  log_name="${executable_name}_${date_string}.log"
  log_file="${log_path}/${log_name}"

  cat >> "$cron_file" << EOF

SHELL=/bin/bash

@reboot ${user} "${executable_file}" 2>&1 | sudo dotpi log "$log_file"
@reboot root rm "$cron_file"

EOF

)

# Usage: sudo dotpi system_update
# equivalent of apt-get update and apt-get dist-upgrade

dotpi_system_update() {
  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  log_file="${DOTPI_ROOT}/var/log/${_dotpi_command}_$(date +"%Y%m%d-%H%M%S").log"
  exec &> >(dotpi log "$log_file")

  dotpi_echo_info "Log of dotpi-manager update: ${log_file}"

  dotpi_echo_info "Update and dist-upgrade"
  dotpi_apt_get update
  dotpi_apt_get dist-upgrade
}
