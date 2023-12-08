#!/bin/bash

# force 32bit executable
# (and kernel for Raspberry Pi v3, not v4)
# 32 for 32bit system, 64 for 64bit system
dotpi_word_size='32'

# dot *not* change this
dotpi_hostname_prefix='dotpi'

dotpi_user='pi'

# no default password:
# - keep the one set by the imager
# - or over-ride in dotpi_environment_project.bash
dotpi_password_hash6=
# # openssl passwd -6
# dotpi_password_hash6='$6$...'

# no default key
dotpi_ssh_authorized_keys=()

dotpi_ssh_allow_password_authentication='yes'

dotpi_timezone='Europe/Paris'

dotpi_keymap='fr'

dotpi_soundcard='default'

# run /opt/dotpi/bin/dotpi_prepare_system after the first reboot
dotpi_prepare_system_automatic='yes'

# Let the user choose (lite or not)
dotpi_apt_uninstall=()

dotpi_apt_install=(
  'ca-certificates'
  'curl'
  'g++'
  'gcc'
  'git'
  'gnupg'
  'make'
  'moreutils' # ts for time-stamp
  'jackd2'
)

dotpi_node_version='lts'
