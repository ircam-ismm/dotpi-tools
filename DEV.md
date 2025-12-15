# Developer documentation

## NPM

This is a mono-repository that uses workspaces and lerna.

To publish a new `minor` version, for any NPM module that changed, commit all changes, then type:

```shell
npx lerna publish`
```

When it fails for some reason, be sure to first log into your NPM account:

```shell
npm login
```

In order to publish an already committed version use:

```shell
npx lerna publish from-git
```

## Working on functions

With `watch` and `rsync` installed on the developer's machine, on can update the functions on a dotpi machine.

```shell
cd 'dotpi-tools/dotpi_root/share/dotpi_functions'
watch "rsync --archive --rsync-path='sudo rsync' --delete --progress --relative './' dotpi-project-000.local:/opt/dotpi/share/dotpi_functions" .
```

Be sure to call the functions with `dotpi` wrapper:

```shell
dotpi echo-info 'Test.'
# same as:
# dotpi echo_info 'Test.'
```

Otherwise, one need to source `dotpi_init.bash` again for the new function to be available.

```shell
source "${DOTPI_ROOT}/share/dotpi_init.bash"
dotpi_echo_info 'Test.'
```
