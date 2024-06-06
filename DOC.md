DOC.md

## Bluetooth  [private]

_do not document for now_

dotpi audio_bluetooth_destination_connect
> connect to bluetooth speaker given a MAC address defined in the $dotpi_audio_bluetooth_mac variable


dotpi_audio_bluetooth_destination_start
> turn on speaker

dotpi_audio_bluetooth_destination_volume_set $1
> set volume and save

dotpi_audio_bluetooth_destination_volume_init
> back to default volume

.cf dotpi_audio_bluetooth_command for an example

## dotpi_functions_dotpi

[sudo] dotpi_dotpi_update
> Update all the `dotpi` sub system

## dotpi_functions_system

dotpi_system_is_raspberry_pi
> return if raspberry pi

[sudo] dotpi_system_set_hostname $1
> change the hostname of the RPi
> $1 - new hostname

[sudo] dotpi_system_execute_on_reboot $1 $2
> Execute file on next reboot
> $1 - user
> $2 - path to file

[sudo] dotpi_system_update
> alias apt-get update and dist upgrade

## dotpi_functions_service

[sudo] dotpi_service_install $1
> $1 service file

[sudo] dotpi_service_uninstall $1
> $1 service name

## dotpi_functions_connection [private]

> manipulate network config files

## dotpi_functions_configuration [private]

> manipulate config files

## dotpi_functions_audio_device

[sudo] dotpi_audio_device_select --model <model>
> select the soundcard

[sudo] dotpi_audio_device_volume_set
[sudo] dotpi_audio_device_volume_init
