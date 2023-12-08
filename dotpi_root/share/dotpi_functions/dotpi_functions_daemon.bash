#!/bin/bash

dotpi_daemon_install() {
  # $1 - path to the `.service` file
  service_file="$1"
  service_name=$(basename -- "${service_file}")

  ln -s "$(dotpi readlink_follow "${service_file}")" /etc/systemd/system/

  systemctl daemon-reload
  # be sure to stop as default or previous version might be running
  systemctl stop "${service_name}"
  systemctl enable "${service_name}"
  systemctl start "${service_name}"
}

dotpi_daemon_uninstall() {
  service_name="$1"

  systemctl stop "${service_name}"
  systemctl disable "${service_name}"
  systemctl daemon-reload
}

dotpi_daemon_restart() {
  service_name="$1"
  systemctl restart "${service_name}"
}
