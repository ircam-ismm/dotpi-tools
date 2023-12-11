# dotpi-install

## Intro

This utility prepares a Raspberry Pi for running in a `dotpi` system. It serves several purposes:

- locally configure a project
- run locally to prepare the SD card
- run on Raspberry Pi to prepare the remote system

## Quick start

In the `project` folder, select a project that is close to your needs: `example-dev` is quite complete.

Do not forget to install the pair SSH keys from `projects/example-dev/secrets/ssh` to local you `${HOME}/.ssh` configuration.

- Download and install the Raspberry Pi Imager.
- Select OS (operating system)
- Choose `Rapsberry Pi OS (other)`
- Choose `Rapsberry Pi OS Lite (64-bit)`
- Insert a new SD card in your computer
- Select it as the storage

- You may change somme settings. In particular, you can choose *not* to eject media when done, to avoid pulling the SD card out, then inserting it again.
- Write the SD card
- You you choose to apply the settings, these will be the defaults before applying the `dotpi` settings

In a terminal:

```sh
# change path to the dotpi-install folder
cd ~/src/dotpi-install

# prepare the SD car with the chosen project
./dotpi_root/bin/dotpi_prepare_sd_card --project ./projects/example-dev
```

Type the instance number, or accept the default. The first instance will be `1`

- Put the SD card into a Raspberry
- Power it on
- Connect it to the internet, and to you computer

You may then copy the last line to get info of the remote process.

Any SSH operation will wait until the network on the Raspberry Pi is ready.

```sh
# This will monitor the first instance of the `dev` project
ssh pi@dotpi-dev-001.local 'tail -f /opt/dotpi/var/log/dotpi_prepare_system_*.log'
```

When done, you can connect.

```sh
ssh pi@dotpi-dev-001.local
```

It should also appear in the `dotpi-manager`.

## Settings

### Raspberry Pi Imager

The installer will first apply the settings of the Raspberry Pi Imager.

In particular:

- host-name

- ssh access
  - you can allow for password authentication (in case the authentication via key fails)

- user and password
  - user name: not recommended to change
  - user password, when ssh is not available

- the wifi settings will be over-ridden

- you can avoid the eject the SD car when done

### Environment defaults

Then, `dotpi-install` will apply the default settings of the `dotpi` environment.

`dotpi_root/etc/dotpi_environment_default.bash`

You should not change anything here. Instead, you can over-ride any value in your projects.

### Project settings

Then, `dotpi-install` will apply the default settings of your project.

#### `configuration` folder

This folder is for "public" settings, that you would share on a repository.

In you project, there is a configuration file named `configuration/dotpi_project.bash`, where you can override any value.

Note that you can also extend settings, by appendind to bash arrays:

```sh
# this add `screen` to the list of packages to install
dotpi_apt_install+=(
  screen
)
```
In particular, you can change the name of your project. (The default is the folder name.)

```sh
dotpi_project_name='dev'
```

The remote machine hosnames will be on the form `dotpi-dev-xxx` with `xxx` as the instance numbers.


You can also choose your sound-card.

```sh
dotpi_soundcard='HiFiBerry DAC+ ADC Pro'
```

##### `jackd` folder

You can add a `jackd` folder in you `<project>/configuration` folder, in order to over-ride jackd settings from `dotpi-root/share/jackd`.

Note that there is a symbolic link to configuration for known sound-cads. If it does not suit your needs, you can use a `dotpi_jackd.bash` configuration file.

```bash
# keep this
DOTPI_JACKD_ENVIRONMENT=(
  JACK_NO_AUDIO_RESERVATION=1
)

# warning: long option for -d (--driver) seems broken

DOTPI_JACKD_ARGUMENTS=(
  --realtime
  --realtime-priority 95
  -d alsa
  --device hw:0
  --playback
  --period 1024
  --nperiods 2
  --rate 48000
)
```

#### `secrets` folder

This folder is for "private" settings, that you would *not* share on a repository.

In you project, there is a configuration file named `secrets/dotpi_secrets.bash`, where you can chage the password.

```sh
dotpi_password='!rapsberry'
```

##### `network` folder

You can add any NetworkManager configuration file. Be sure *not* to quote values, including `ssid` and `psk`, as anything is part of the value, including quotes.

To keep the automatic configuration for the ethernet interface, do not add it here.

To keep `NetworkManager` functional, do *not* configure network in an other way (ie. no `wpa_supplicant.conf` file).

##### `ssh` folder

Be sure to install the pair of SSH keys in you `${HOME}/.ssh` configuration.

### Instance settings, `tmp` folder

The last step is to apply particular settings relative to the instance.

After sucessfully preparing an SD card, a copy of the last settings will be in your pject, in a `tmp` folder.

- `dotpi_prepare_sd_card_*.log` is a copy of the screen messages
- `dotpi_tmp.bash` contains the instance number (to increment for the next time)
- `file-system` is a full copy of what will be installed on the Raspberry Pi.

## On the Raspberry Pi

Any system-wide installation will link to the `/opt/dotpi` directory. Except two things.

The `/boot/firmware` folder (mounted as `/bootfs` as a local SD card) contains the `config.txt` file.

Node is installed via `n` in `/home/pi/n` and linked in `/usr/bin/`.


### Commands

Use `dotpi` or `sudo dotpi` to run any `dotpi_function` function.

### `/boot/firmware` `/bootfs`

- `config.txt` is the hardware configuration file.
- `firstrun_*.log` is the log the the first run
  - Intentionnaly, the network does not start at this stage
- the `dotpi` folder contains the initial version of the `dotpi` file-system, and a non-customised version of the `firstrun.sh` script from the imager.

### `/opt/dotpi`

`/opt/dotpi/bin/dotpi` is the main executable, installed in `/usr/bin`

#### `/opt/dotpi/etc`

- `config.txt` is an *initial* copy of the hardware configuration. It may diverge after any mofdification.
- `dotpi_environment_*.bash` contain the customisation of the environment
- `network` contains the network configuration, that where copied to `/etc/NetworkManager/system-connections`. It may diverge after any mofdification.
- `ssh` contains the public SSH keys that were copied to `${HOME}/.ssh/authorized_keys`

#### `/opt/dotpi/share`

- `dotpi-manager` contains the client and the service
- `jackd` contains the configuration and the service
- `limits` contains the limits that were copied to `/etc/security/limits.d`

#### `/opt/dotpi/var/log`

Log files.

- `dotpi_prepare_system_*.log` contains the log of the system preparation

#### `/home/pi/n`

Node is installed via `n` in `/home/pi/n/bin/node` and linked in `/usr/bin/node`

#### `/usr/local/bin`

This is an alias to `/usr/bin`.

### Other

#### Local machine

If you install `wpa_passphrase`, wifi passwords will be hashed.

You should install the version 3 of `rsync` to get quicker transfer times with `dotpi-manager`.

```sh
rsync --version | grep version
```

#### Remote Raspberry Pi


##### Network

Everything is managed via `NetworkManager`. You can use `nmtui` to use a user-interface.

You also directly use `nmcli` with a command-line interface.

```sh
nmcli device
# DEVICE         TYPE      STATE                   CONNECTION
# eth0           ethernet  connected               Wired connection 1
# lo             loopback  connected (externally)  lo
# wlan0          wifi      disconnected            --
# p2p-dev-wlan0  wifi-p2p  disconnected            --

nmcli radio
# WIFI-HW  WIFI     WWAN-HW  WWAN
# enabled  enabled  missing  enabled
```


##### `jackd`

In order to play soundfiles via `jackd`, you can install `mpv`

```sh
mpv --ao=jack 'sound.mp3'
```

You can monitor a jack connection in a terminal with. Warning, you need to install the `jackmeter` package but the command is `jack_meter`.

```sh
# list jack connections
jack_lsp
# system:capture_1
# system:capture_2
# system:playback_1
# system:playback_2
# cpal_client_out:out_0
# cpal_client_out:out_1
# cpal_client_out-01:out_0
# cpal_client_out-01:out_1

# monitor the system output
jack_meter system:playback_1

# monitor a particular connection
jack_meter mpv:out_0
```

##### Raspberry pi

You can get various information about the hardware and software.

```sh
cat /proc/device-tree/model
# Raspberry Pi 4 Model B Rev 1.4pi

# 64bit kernel (even for 32bit system)
uname -a
# Linux dotpi-dev-019 6.1.21-v8+ #1642 SMP PREEMPT Mon Apr  3 17:24:16 BST 2023 aarch64 GNU/Linux

# 64bit kernel (even for 32bit system)
arch
# aarch64

# 32bit system
file $(which file)
# /usr/bin/file: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, BuildID[sha1]=f5f7f7c84dbb609f53ae3b9ac6b4437d927bde7d, for GNU/Linux 3.2.0, stripped
```

## Known bugs

Please do report them.

## Todo

- [ ] use 64bit system as default configuration

- [ ] publish on github
  - [ ] remove any secret (no history)
  - [ ] publish secrets in examples

- [ ] Make a command-line interface
  - [ ] choose between options
    - [ ] project name
    - [ ] sound-card model
    - [ ] jackd configuration
  - [ ] make pair of ssh keys
  - [ ] wifi/network configuration
