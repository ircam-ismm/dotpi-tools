#!/bin/bash

#### default functions

for file in "${DOTPI_ROOT}/share/dotpi_functions/"* ; do
  source "$file"
done

#### dotpi-manager

dotpi_source_if_available "${DOTPI_ROOT}/share/dotpi-manager/dotpi_manager.bash"
