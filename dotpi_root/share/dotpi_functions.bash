#!/bin/bash

#### default functions

while IFS= read -r -d '' source_file ; do
  # continue on error
  source "$source_file" || true
done < <( find "${DOTPI_ROOT}/share/dotpi_functions" -name '*.bash' -type f -print0 )


# @TODO remove after migration to dotpi modules
# continue on error
dotpi_source_if_available "${DOTPI_ROOT}/share/dotpi-manager/dotpi-manager.bash" || true
dotpi_source_if_available "${DOTPI_ROOT}/share/dotpi-led/dotpi-led.bash" || true
