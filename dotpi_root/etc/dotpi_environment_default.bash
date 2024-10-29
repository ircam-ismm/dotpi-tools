#!/bin/bash

# variables are used in dotpi_environment.bash, not in this file
# shellcheck disable=SC2034

# force 32bit executable
# (and kernel for Raspberry Pi v3, not v4)
# 32 for 32bit system, 64 for 64bit system
# only applies if the system is in 32 bits
dotpi_word_size='32'

# dot *not* change this
dotpi_hostname_prefix='dotpi'

dotpi_user='pi'

# no default password: set `dotpi_password` in <project>/secrets/dotpi_secrets.bash
dotpi_password=

# no default key
dotpi_ssh_authorized_keys=()

dotpi_ssh_allow_password_authentication='yes'

dotpi_timezone='Europe/Paris'

dotpi_keymap='fr'

dotpi_audio_device='default'

# run /opt/dotpi/bin/dotpi_prepare_system after the first reboot
dotpi_prepare_system_automatic='yes'

# install dotpi-manager service
dotpi_manager_install='yes'

# install dotpi-led service
dotpi_led_install='no'
dotpi_led_strip_configuration='default'

# Let the user choose (lite or not)
dotpi_apt_uninstall=()

dotpi_apt_install=(
  'systemd-container' # machinectl

  'ca-certificates'
  'curl'
  'g++'
  'gcc'
  'git'
  'gnupg'
  'make'
  'cmake'
  'scons'

  'pipewire'
  'pipewire-audio'
  'pipewire-jack'
)

dotpi_node_version='lts'
