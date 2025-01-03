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

# no default password: set `dotpi_password` in <project>/dotpi_secrets.bash
dotpi_password=

# no default key
dotpi_ssh_authorized_keys=()

dotpi_ssh_allow_password_authentication='yes'

dotpi_timezone='Europe/Paris'
dotpi_wifi_country_code='FR'
dotpi_keymap='fr'

dotpi_audio_device='default'

# run /opt/dotpi/bin/dotpi_prepare_system after the first reboot
dotpi_prepare_system_automatic='yes'

# install dotpi-manager service
dotpi_manager_install='yes'

# install dotpi-led service
dotpi_led_install='no'
dotpi_led_strip_configuration='default'

# system default
dotpi_apt_uninstall_default=()

# user-defined, use +=(package1 package2) to add packages to list
dotpi_apt_uninstall=()

# dotpi requirements
dotpi_apt_install_default=(
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

# user-defined, use +=(package1 package2) to add packages to list
dotpi_apt_install=()

# system default
dotpi_module_uninstall_default=()

# user-defined, use +=(package1 package2) to add packages to list
dotpi_module_uninstall=()

# system default
dotpi_module_install_default=(
  '@dotpi/module'
  '@dotpi/avahi_monitor'
)

# user-defined, use +=(package1 package2) to add packages to list
dotpi_module_install=()

dotpi_node_version='lts'
