# Notes

## TODOS

### General

- [ ] Documentation when each of the following step is clean
- [ ] Create test scenarios
  - provide mocks to prompts & compare output with predefined results
- [ ] Best effort for Linux and Windows, even if it's just a message w/ a link to ouside source

### Features

- [ ] test projects created with `createProject`
  + review `configureSSH` keys to handle other platforms when generating keys
- [ ] implement and test `prepareRpi`
  - just wrap `dotpi_prepare_system`, see SSH feedback by default
- [ ] first pass on re-organizing files and folder (only on js side)
  + [x] move all file templates into their own file for easier maintenance
- [ ] check we have a MVP w/ JIP and converge to final structure
  + [ ] see what it means to have `projects` living in it own user-defined location
- [ ] implement and test `configureHost` script
  + for adding SSH keys, just point to gihub doc if not on MacOS for now
    Linux should be rather straightforward,
- [ ] check platform for all commands and warn if not macOS
- [ ] rename? `@dotpi/tools` rather than `@dotpi/install`
- [ ] make it work using `npx`

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