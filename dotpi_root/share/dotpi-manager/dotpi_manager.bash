#!/bin/bash

dotpi_manager_update() {
  cd -- "${DOTPI_ROOT}/share/dotpi-manager/runtime"

  git pull origin main
  rm -Rf node_modules
  npm install
  npm run build

  dotpi_daemon_restart dotpi-manager.service
}
