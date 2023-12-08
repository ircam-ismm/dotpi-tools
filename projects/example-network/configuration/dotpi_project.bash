#!/bin/bash

dotpi_project_name='example'

dotpi_ssh_allow_password_authentication='yes'

dotpi_timezone='Europe/Paris'
dotpi_keymap='fr'

dotpi_soundcard='HiFiBerry DAC+ ADC Pro'

# add packages
# be sure to keep the parentheses, even for a single line
dotpi_apt_install+=(
  'jackmeter' # monitor sound activity in console
  # 'locate'
  'dnsutils' # dig
  'nmap' # test clients in network
  'screen' # detach sessions
  # 'mpv' # play soundfiles via jackd
)
