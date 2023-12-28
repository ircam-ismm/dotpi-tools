#!/bin/bash

#### default functions

for file in "${DOTPI_ROOT}/share/dotpi_functions/"* ; do
  # continue on error
  source "$file" || true
done

#### dotpi-manager

# continue on error
dotpi_source_if_available "${DOTPI_ROOT}/share/dotpi-manager/dotpi_manager.bash" || true
