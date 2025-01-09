# Notes

## TODOS

### Fix

- [x] `--install-rpi` do not work when inside a project
- [x] modify message to eject SD card when on Windows

### General

- [ ] Documentation when each of the following step is clean
- [ ] Create test scenarios
  - provide mocks to prompts & compare output with predefined results
- [ ] Best effort for Linux and Windows, even if it's just a message w/ a link to ouside source

### Features

- [x] parse path of ssh key (~/.ssh/ ${HOME}/.ssh)
- [ ] check platform for all commands and warn if not macOS
- [ ] test projects created with `createProject`
  + review `configureSSH` keys to handle other platforms when generating keys
- [ ] remove `/jackd` stuff in `dotpi_prepare_sd_card`
- [x] implement and test `prepareRpi`
  - just wrap `dotpi_prepare_system`, see SSH feedback by default
- [x] first pass on re-organizing files and folder (only on js side)
  + [x] move all file templates into their own file for easier maintenance
- [x] check we have a MVP w/ JIP and converge to final structure
  + [x] see what it means to have `projects` living in it own user-defined location
- [x] implement and test `configureHost` script
  + for adding SSH keys, just point to gihub doc if not on MacOS for now
    Linux should be rather straightforward,
- [x] rename to `@dotpi/tools` rather than `@dotpi/install`
- [x] make it work using `npx`

### Modules

#### support apt dependencies

- [ ] add `aptDependecies` to `package.json`
- [ ] generate `<package>/DEBIAN/control` file from `package.json`

```
Package: ${package.name.replace(/@/, '').toLowerCase().replace(/[^a-z0-9.+-]/, '-')
}
Description: ${package.description}
Version: ${package.version || '0.0.0'}
Maintainer: ${package.maintainer || 'nobody <no@mail.com>'}
Section: embedded
Priority: optional
Architecture: all
Standards-Version: 11.0.0
Depends: ${package.aptDependencies}
```

- [ ] `dotpi_install`:
  - [ ] `sudo dotpi module install apt-packages`
  - [ ] generate debian package and install

 ```sh
sudo dpkg-deb --root-owner-group --build <package>
sudo chmod a+rw <package>
sudo cp <package> /tmp
sudo dotpi apt-get install /tmp/<package>
```

- [ ] `dotpi_uninstall`:
  - [ ]`sudo dotpi module uninstall apt-packages`
  - [ ] uninstall debian package

```sh
sudo apt-get uninstall <package>
sudo dotpi apt-get autoremove

```

## Questions

- [ ] add a level of indirection in config files?
  + datas stored in yml or something, would help maintainance?
- [ ] system to check for new version
  + `npm view @soundworks/core version`

## Final File Structure

```sh
# (-> `dotpi_root`), cf. move toward .deb package?
# cf https://www.iodigital.com/en/history/intracto/creating-debianubuntu-deb-packages
# maybe overkill for us... https://unix.stackexchange.com/a/620698
pkg
src
  lib

  wizard.js # one single js bin so that we can execute the command from npx, cf. above
docs # -> or use another dedicated repo `ircam-ismm/dotpi`
README.md
LICENSE
package.json
```

## Example Use

```sh
# npm install -g @dotpi/tools

# my-dotpi-projects is just a reglar directory
cd ../my-dotpi-projects

# # cf. https://stackoverflow.com/a/58649605
# npx @dotpi/tools --create-project
# npx @dotpi/tools --configure-host
# npx @dotpi/tools --install-rpi
# npx @dotpi/tools --launch-manager



npx dotpi-tools --create-project
npx dotpi-tools --configure-host
npx dotpi-tools --install-rpi
npx dotpi-tools --launch-manager
```
