#!/bin/bash

dotpi_bluetooth_enable() {

  if [[ "$USER" != "root" ]]; then
    dotpi echo_error "This command must be run as root"
    return 1
  fi

  dotpi_echo_info "Enabling Bluetooth"

  bluetoothctl power off
  rfkill unblock bluetooth
  systemctl restart bluetooth
  bluetoothctl power on
}
