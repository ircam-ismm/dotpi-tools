#!/bin/bash

_dotpi_audio_bluetooth_controller='hci0'

# bash v5 is available on Raspberry Pi, and provides named co-processes
if (( "${BASH_VERSINFO:-0}" < 5 )) ; then
  return 0;
fi
# connect an audio bluetooth device, corresponding to dotpi_audio_bluetooth_mac,
# using bluetoothctl,
dotpi_audio_bluetooth_destination_connect() (
  destination_mac="$dotpi_audio_bluetooth_mac"

  dotpi_echo_info "Starting bluetoothctl process"
  status='init'
  coproc btctl_process { bluetoothctl; }

  while IFS= read -r output ; do
    echo "$output" >&2

    if [[ "$status" == 'init' ]]; then
      dotpi_echo_info "Registering agent"
      echo "default-agent" >&${btctl_process[1]}
      echo "agent on" >&${btctl_process[1]}

      dotpi_echo_info "Starting scan"
      echo "scan on" >&${btctl_process[1]}
      status='starting scan'
    fi

    if [[ "$status" == "starting scan" ]] \
         && [[ "$output" =~ "Discovery started" ]] ; then
      dotpi_echo_info "Waiting for destination"
      status='scanning'
    fi

    if [[ "$status" == "scanning" ]] \
         && [[ "$output" =~ Device.*"$destination_mac" ]] ; then
      dotpi_echo_info "Destination discovered"
      status='destination discovered'
    fi

    if [[ "$status" == 'destination discovered' ]] ; then
      dotpi_echo_info "Pairing destination"
      echo "pair ${destination_mac}" >&${btctl_process[1]}
      status='pairing'
    fi

    if [[ "$status" == "pairing" ]] \
         && [[ "$output" =~ "Pairing successful" ]] ; then
      dotpi_echo_info "Destination paired"
      status='destination paired'
    fi

    if [[ "$status" == "pairing" ]] \
         && [[ "$output" =~ "Failed to pair" ]] ; then
      dotpi_echo_error "Paring failed"
      dotpi_echo_warning "Turn destination on, in discovery mode"
      sleep 1
      echo "pair ${destination_mac}" >&${btctl_process[1]}
      status='pairing'
    fi

    if [[ "$status" == "destination paired" ]] ; then
      dotpi_echo_info "Connecting destination"
      echo "connect ${destination_mac}" >&${btctl_process[1]}
      status='connecting'
    fi

    if [[ "$status" == "connecting" ]] \
         && [[ "$output" =~ "Connection successful" ]] ; then
      dotpi_echo_info "Destination connected"
      status='destination connected'
    fi

    if [[ "$status" == "destination connected" ]] ; then
      dotpi_echo_info "Trusting destination"
      echo "trust ${destination_mac}" >&${btctl_process[1]}
      status='trusting'
    fi

    if [[ "$status" == "trusting" ]] \
         && [[ "$output" =~ "trust succeeded" ]] ; then
      dotpi_echo_info "Destination trusted"
      status='destination trusted'
    fi

    if [[ "$status" == "destination trusted" ]] ; then
      dotpi_echo_info "Ending scan"
      echo "scan off" >&${btctl_process[1]}
      status='ending scan'
    fi

    if [[ "$status" == "ending scan" ]] \
         && [[ "$output" =~ "Discovery stopped" ]] ; then
      dotpi_echo_info "Exiting"
      status='exiting'
    fi

    if [[ "$status" == 'exiting' ]] ; then
      echo "exit" >&${btctl_process[1]}
      dotpi_echo_info "Done"
      status='done'
      break
    fi

  done <&${btctl_process[0]}
)

dotpi_audio_bluetooth_destination_disconnect() (
  bluetoothctl -- remove "$dotpi_audio_bluetooth_mac"
)

_dotpi_audio_bluetooth_destination_start_ue() (
  destination_mac="$dotpi_audio_bluetooth_mac"
  destination_descriptor="${dotpi_audio_bluetooth_mac//:/_}"

  trusted_mac="$(hciconfig "$_dotpi_audio_bluetooth_controller" \
     | perl -ne 'if (m/BD Address:\s*([\w:]+).*$/i) { print "${1}\n"; }')"

  coproc btctl_process { bluetoothctl; }

  # test if already here
  echo 'transport.list' >&${btctl_process[1]}

  timeout_duration=30
  timeout "$timeout_duration" gatttool \
    --adapter "$_dotpi_audio_bluetooth_controller" \
    --device "${destination_mac}" \
    --char-write-req \
    --handle 0x0003 \
    --value "${trusted_mac//:/}01" || {
      timeout_status="$?"
      case "$timeout_status" in
        '124')
          timeout_message="time out"
          ;;

        '125')
          timeout_message="failed"
          ;;
        '126')
          timeout_message="cannot be invoked"
          ;;
        '127')
          timeout_message="not found"
          ;;
        '137')
          timeout_message="killed"
          ;;
        *)
          timeout_message="exit status: ${timeout_status}"
          ;;
      esac
      dotpi_echo_error "Unable to start ${dotpi_audio_device}: ${timeout_message}"
      
      return_value="$?"
      kill ${btctl_process_PID}
      return "$return_value"
  }

  while IFS= read -r output ; do
    echo "$output" >&2

    # Connected and transport volume available
    if [[ "$output" =~ [CHG].*Transport.*/org/bluez/.*dev_"${destination_descriptor}".*Volume ]] \
         || [[ "$output" =~ ^Transport.*/org/bluez/.*dev_"${destination_descriptor}" ]] ; then
      kill ${btctl_process_PID}
      break
    fi
  done <&${btctl_process[0]}

)

# turn audio device on, and set volume
dotpi_audio_bluetooth_destination_start() (
  model_normalised="$(dotpi_audio_device_model_normalise "$dotpi_audio_device")"

  case "$model_normalised" in

    'ue boom 2'|'ue boom 3'|'ue megaboom 2'|'ue megaboom 3')
      _dotpi_audio_bluetooth_destination_start_ue
      ;;

    *)
      dotpi_echo_error "Unable to start unknown model '${dotpi_audio_device}'"
      return 1
      ;;

  esac

  dotpi_audio_bluetooth_destination_volume_init
)


_dotpi_audio_bluetooth_destination_stop_ue() (
  destination_mac="$dotpi_audio_bluetooth_mac"
  destination_descriptor="${dotpi_audio_bluetooth_mac//:/_}"

  trusted_mac="$(hciconfig "$_dotpi_audio_bluetooth_controller" \
     | perl -ne 'if (m/BD Address:\s*([\w:]+).*$/i) { print "${1}\n"; }')"

  dotpi echo_info "Starting bluetoothctl monitor process"
  coproc btctl_process { bluetoothctl; }

  # will trigger a connection, even if destination if off, for write request (BLE)
  # hence the [CHG] ... Connected: no
  timeout_duration=30
  timeout "$timeout_duration" gatttool \
    --adapter "$_dotpi_audio_bluetooth_controller" \
    --device "${destination_mac}" \
    --char-write-req \
    --handle 0x0003 \
    --value "${trusted_mac//:/}02" || {
      timeout_status="$?"
      case "$timeout_status" in
        '124')
          timeout_message="time out"
          ;;

        '125')
          timeout_message="failed"
          ;;
        '126')
          timeout_message="cannot be invoked"
          ;;
        '127')
          timeout_message="not found"
          ;;
        '137')
          timeout_message="killed"
          ;;
        *)
          timeout_message="exit status: ${timeout_status}"
          ;;
      esac
      dotpi_echo_error "Unable to stop ${dotpi_audio_device}: ${timeout_message}"

      return_value="$?"
      kill ${btctl_process_PID}
      return "$return_value"
  }

  while IFS= read -r output ; do
    echo "$output" >&2

    # destination disconnected
    if [[ "$output" =~ [DEL].*Endpoint.*/org/bluez/.*dev_"${destination_descriptor}" ]] \
         || [[ "$output" =~ [CHG].*Device.*"$destination_mac".*Connected:.*no ]] ; then

      kill ${btctl_process_PID}
      break
    fi
  done <&${btctl_process[0]}
)

# turn off audio device
dotpi_audio_bluetooth_destination_stop() (
  model_normalised="$(dotpi_audio_device_model_normalise "$dotpi_audio_device")"

  case "$model_normalised" in

    'ue boom 2'|'ue boom 3'|'ue megaboom 2'|'ue megaboom 3')
      _dotpi_audio_bluetooth_destination_stop_ue
      ;;

    *)
      dotpi_echo_error "Unable to stop unknown model '${dotpi_audio_device}'"
      return 1
      ;;

    esac
)

# set and save volume
dotpi_audio_bluetooth_destination_volume_set() (
  destination_volume="$1"
  destination_device="dev_${dotpi_audio_bluetooth_mac//:/_}"
  destination_transport="$(bluetoothctl transport.list \
    | perl -ne 'if(m/Transport\s+(\/*${destination_device}[^\s]+).*$/) { print "${1}\n"; }')"

  if [[ -z "$destination_transport" ]] ; then
    dotpi_echo_error "Failed to set volume: audio bluetooth device not found"
    return 1
  fi

  bluetoothctl transport.volume "$destination_transport" "$destination_volume"
  if (( $? != 0 )) ; then
    dotpi_echo_error "Failed to set bluetooth destination volume"
    return 1
  else
    dotpi_echo_info "Bluetooth destination volume set to ${destination_volume}"
  fi

  if [[ "$destination_volume" ==  "$dotpi_audio_volume" ]] ; then
    # no change to write
    return 0
  fi

  # comment setting in project
  dotpi_configuration_comment --file "${DOTPI_ROOT}/etc/dotpi_environment_project.bash" \
                              --key dotpi_audio_volume

  # escape double-quote for now, to quote when writing later
  model_value="$(echo "$model" | dotpi_sed 's/"/\\"/g')"

  # write changed setting in instance
  dotpi_configuration_write --file "${DOTPI_ROOT}/etc/dotpi_environment_instance.bash" \
                            --key dotpi_audio_volume \
                            --value "$destination_volume"

)

# set volume to default
dotpi_audio_bluetooth_destination_volume_init() (
  if [[ -z "$dotpi_audio_volume" ]] ; then
    dotpi_echo_warning "dotpi_audio_volume not set, keeping default volume"
    return 0
  fi

  destination_volume="$dotpi_audio_volume"
  dotpi_audio_bluetooth_destination_volume_set "$destination_volume"
)

