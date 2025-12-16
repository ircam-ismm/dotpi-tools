# dotpi-install

## Intro

This utility prepares a Raspberry Pi for running in a `dotpi` distributed system. It serves several purposes:

- locally configure a project
- run locally to prepare the SD card
- run on Raspberry Pi to prepare the remote system
- add utilities and services to the remote system

## Getting started

See the documentation [here](https://ircam-ismm.github.io/dotpi/)

## Known bugs

Please do report them.

## Todo

- [ ] dotpi-manager: dependency to audio should be soft
  - [ ] allow client to run without audio
  - [ ] client should continue to run if audio stops

- [ ] @dotpi/audio-module
  - [ ] generate
  - [ ] soft limiter at audio output
    - [ ] pipewire filter-chain
      Cf. <https://flaterco.com/kb/audio/pipewire/volume.html>
    - [ ] easy effect
      Cf. <https://github.com/wwmm/easyeffects/wiki/Command-Line-Options>
