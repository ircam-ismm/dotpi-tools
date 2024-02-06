#!/bin/bash

dotpi_project_name='example'

dotpi_ssh_allow_password_authentication='yes'

dotpi_audio_device='HiFiBerry DAC+ ADC Pro'

# add packages
# be sure to keep the parentheses, even for a single line
dotpi_apt_install+=(
  # 'dnsutils' # dig
  'jackmeter' # monitor sound activity in console
  # 'locate'
  # 'nmap' # test clients in network
  'screen' # detach sessions
  # 'mpv' # play soundfiles via jackd
)
