#!/bin/bash

# @dotpi/tools version
dotpi_tools_version='${d.version}'

# Project name
dotpi_project_name='${d.projectName}'

# Define soundcard
dotpi_audio_device='${d.soundCard}'

# Node.js version
dotpi_node_version='${d.nodeVersion}'

# Install dotpi-manager service
dotpi_manager_install='${d.installDotpiManager ? 'yes' : 'no'}'

# Install dotpi-led service
dotpi_led_install='${d.installDotpiLed ? 'yes' : 'no'}'
${d.installDotpiLed ? `\
dotpi_led_strip_configuration='${d.dotPiLedConfigFile}'` : ``}

# Misc
dotpi_timezone='${d.timeZone}'
dotpi_keymap='${d.keyMap}'

# If you want to have some packages to be automatically installed
# or removed by default, you can list them in the arrays above
dotpi_apt_install=()
dotpi_apt_uninstall=()