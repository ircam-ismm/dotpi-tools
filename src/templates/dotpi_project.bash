#!/bin/bash

# @dotpi/tools version
dotpi_tools_version='${d.version}'

# Project name
dotpi_project_name='${d.projectName}'

# Define soundcard
dotpi_audio_device='${d.soundCard}'

# Node.js version
dotpi_node_version='${d.nodeVersion}'

# User-defined dotpi modules to install
dotpi_module_install+=(
  ${!d.installDotpiManager ? '# ' : ''}'@dotpi/manager'
  ${!d.installDotpiLed ? '# ' : ''}'@dotpi/led'
)

# Misc
dotpi_timezone='${d.timeZone}'
dotpi_wifi_country_code='${d.wifiCountryCode}'
dotpi_keymap='${d.keyMap}'

# If you want to have some packages to be automatically installed
# or removed by default, you can list them in the arrays below
dotpi_apt_install+=()
dotpi_apt_uninstall+=()
