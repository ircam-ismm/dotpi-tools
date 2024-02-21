#!/bin/bash

dotpi_project_name='example'

# default is yes
dotpi_ssh_allow_password_authentication='yes'

# no default password:
# - keep the one set by the imager
# - or over-ride in dotpi_environment_project.bash
dotpi_password_hash=
# # openssl passwd -1
# dotpi_password_hash='$1$...'

dotpi_timezone='Europe/Paris'
dotpi_keymap='fr'

dotpi_audio_device='HiFiBerry DAC+ ADC Pro'

# use node.js specific version
# default is lts
dotpi_node_version='lts'

# add packages
# be sure to keep the parentheses, even for a single line
dotpi_apt_install+=(
  #### utilities ####

  # 'locate' # find files
  'screen' # detach sessions


  #### compilation ####

  'cmake'
  'make'
  'scons'


  #### network ####

  'dnsutils' # dig
  'nmap' # test clients in network


  #### audio ####

  'jackmeter' # monitor sound activity in console
  # 'mpv' # play soundfiles via jackd
  # 'sox' # manipulate soundfile
  # 'vlc' # play soundfiles via jackd

  #### bluetooth ####

  # 'bluez'
  # 'bluez-alsa'
  # 'bluez-alsa-utils' # bluealsa-aplay to get sound from Bluetooth
  # 'bluez-tools'
)
