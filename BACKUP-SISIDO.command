#!/bin/bash

# Double-click
cd "$(dirname "$0")" || exit 0

# explicitly add symbolic links to directories relative paths, ending with '/'
SRC=(
    './'
)

DST="/Volumes/SISIDO/svg/$(basename "$(pwd)")"
BAK="${DST}/../$(basename "${DST}.bak")/$(date '+%Y-%m-%d_%H-%M-%S')"

EXCLUDE_FLAGS=(
    --exclude 'max-include-test' # big and not specific
    --exclude 'CVS/' # centralised
    --exclude '.svn/' # centralised
    --exclude 'node_modules/' # node
    --exclude 'site-packages/' # python
)

mkdir -p "${DST}"

# --extended-attributes    update the destination ACLs to be the same as the source ACLs
# --archive                turn on archive mode (recursive copy + retain attributes)
# --delete                 delete any files that have been deleted locally
# --delete-excluded        delete any files (on DST) that are part of the list of excluded files
# --exclude-from           reference a list of files to exclude
# --hard-links             preserve hard-links
# --one-file-system        don't cross device boundaries (ignore mounted volumes)
# --sparse                 handle sparse files efficiently
# --verbose                increase verbosity

rsync_version="$(rsync --version)"

if [[ ${rsync_version} =~ 'xattrs' ]] ; then
    # rsync 3
    sudo rsync --verbose \
         --archive \
         --hard-links \
         --xattrs \
         --acls \
         --one-file-system \
         --delete \
         "${EXCLUDE_FLAGS[@]}" \
         --backup --backup-dir="${BAK}" \
         --relative "${SRC[@]}" "${DST}"
else
    # rsync 2
    sudo rsync --verbose \
         --archive \
         --hard-links \
         --extended-attributes \
         --one-file-system \
         --delete \
         "${EXCLUDE_FLAGS[@]}" \
         --backup --backup-dir="${BAK}" \
         --relative "${SRC[@]}" "${DST}"
fi
sudo -k

