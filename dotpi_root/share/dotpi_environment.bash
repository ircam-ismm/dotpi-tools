#!/bin/bash

dotpi_source_if_available "${DOTPI_ROOT}/etc/dotpi_environment_default.bash"
dotpi_source_if_available "${DOTPI_ROOT}/etc/dotpi_environment_project.bash"
dotpi_source_if_available "${DOTPI_ROOT}/etc/dotpi_environment_instance.bash"
