#!/bin/bash

dotpi_project_name='example'

# default to "yes" (password and/or ssh keys must be defined in "secrets")
dotpi_ssh_allow_password_authentication='yes'

# define soundcard
dotpi_audio_device='HiFiBerry DAC+ ADC Pro'

# define node.js version (defaults to lts)
dotpi_node_version='lts'

# add packages (make sure to keep the parentheses, even for a single line)
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
