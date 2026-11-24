#!/bin/bash

dotpi_bluetooth_enable() {

  dotpi_echo_info "Enabling Bluetooth"

  bluetoothctl power off
  sudo rfkill unblock bluetooth
  sudo systemctl restart bluetooth
  bluetoothctl power on
}
