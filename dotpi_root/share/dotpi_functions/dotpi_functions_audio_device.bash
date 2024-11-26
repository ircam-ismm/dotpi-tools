#!/bin/bash

dotpi_audio_device_supported=(
  'default'
  'none'
  'headphones'
  'hifiberry dac+ adc pro'
  'hifiberry dac+ adc'
  'hifiberry dac+ standard'
  'hifiberry dac+ light'
  'hifiberry dac zero'
  'hifiberry miniamp'
  'hifiberry beocreate'
  'hifiberry dac+ dsp'
  'hifiberry dac+ rtc'
  'hifiberry pro'
  'hifiberry amp2'
  'hifiberry dac2 hd'
  'hifiberry digi+'
  'hifiberry digi+ pro'
  'hifiberry amp+'
  'hifiberry amp3'
  'hifiberry dac for raspberry pi 1'
  'raspberry pi dac pro'
  'raspberry pi dac+'
  'raspberry pi digiamp+'
  'raspberry pi codec zero'
  'iqaudio pi dac pro'
  'iqaudio pi dac+'
  'iqaudio pi digiamp+'
  'iqaudio pi codec zero'
  'bluetooth'
  'ue boom 2'
  'ue boom 3'
  'ue megaboom 2'
  'ue megaboom 3'
)

_dotpi_audio_device_get_options() {

  _echo_empty_option_error() {
    dotpi_echo_error "$1 requires a non-empty option argument."
  }

  # From http://mywiki.wooledge.org/BashFAQ/035

  while true ; do
    case $1 in

      -h|-\?|--help)
        _dotpi_usage    # Display a usage synopsis.
        return 0
        ;;

      -m|--model)       # Takes an option argument; ensure it has been specified.
        if [ -z "$2" ] ; then
            _dotpi_usage
            _echo_empty_option_error "$1"
            return 1
        else
            model="$2"
            shift
        fi
        ;;

      -c|--config)       # Takes an option argument; ensure it has been specified.
        if [ -z "$2" ] ; then
            _dotpi_usage
            _echo_empty_option_error "$1"
            return 1
        else
            config_file="$2"
            shift
        fi
        ;;

      --)              # End of all options.
        shift
        break
        ;;

      -?*) # Unknown
        _dotpi_usage
        dotpi_echo_error "Unknown option: $1"
        return 1
        ;;

      *)               # Default case: No more options, so break out of the loop.
        break

    esac

    shift
  done

}

dotpi_audio_device_model_normalise() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Usage: sudo dotpi audio_device_select --model <model> [--config <config_file_path>]
# if --config is not provided, it will use the system default config file
dotpi_audio_device_select() (
  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} --model <model> [--config <config_file_path>]"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  model=
  config_file=

  if ! _dotpi_audio_device_get_options "${@}" ; then
    return $?
  fi

  if [ -z "$model" ] ; then
    _dotpi_usage
    dotpi_echo_error "missing model option"
    return 1
  fi

  if [ -z "$config_file" ] ; then
    config_path="$(dotpi_system_get_bootfs_path)"
    if [ -z "$config_path" ] ; then
      dotpi_echo_error "Unable to get default system path for config file"
      _dotpi_usage
      return 1
    fi
    config_filename='config.txt'
    config_file="${config_path}/${config_filename}"
    dotpi_echo_warning "Using default config file ${config_file}"
  fi


  if ! [ -w "$config_file" ] ; then
    dotpi_echo_error "Unable to access config file ${config_file} for writing"
    return 1
  fi

  # lowercase everything
  model_normalised="$(dotpi_audio_device_model_normalise "$model")"

  case "$model_normalised" in

    ######## Generic devices

    'default')
      dotpi_echo_warning "Not installing a specific audio device, keeping defaults"
      ;;

    'none')
      _dotpi_audio_device_disable_all
      ;;

    'headphones')
      _dotpi_audio_device_select_headphones
      ;;

    'bluetooth')
      dotpi_echo_info "Installing generic bluetooth device"
      _dotpi_audio_device_select_bluetooth
      ;;

    ######## Specific devices

    # Raspberry
    # Cf. https://www.raspberrypi.com/documentation/accessories/audio.html#configuration

    'raspberry pi dac pro'|'iqaudio pi dac pro')
      dtoverlay=rpi-dacpro
      _dotpi_audio_device_select_raspberry_pi
      ;;

    'raspberry pi dac+'|'iqaudio pi dac+')
      dtoverlay=rpi-dacplus
      _dotpi_audio_device_select_raspberry_pi
      ;;

    'raspberry pi digiamp+'|'iqaudio pi digiamp+')
      dtoverlay=rpi-digiampplus
      _dotpi_audio_device_select_raspberry_pi
      ;;

    'raspberry pi codec zero'|'iqaudio pi codec zero')
      dtoverlay=rpi-codeczero
      _dotpi_audio_device_select_raspberry_pi
      ;;

    # HiFiBerry
    # Cf. https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/

    'hifiberry dac for raspberry pi 1'|'hifiberry dac+ light'|'hifiberry dac zero'|'hifiberry miniamp'|'hifiberry beocreate'|'hifiberry dac+ dsp'|'hifiberry dac+ rtc')
      dtoverlay=hifiberry-dac
      _dotpi_audio_device_select_hifiberry
      ;;

    'hifiberry dac+ standard'|'hifiberry pro'|'hifiberry amp2')
      dtoverlay=hifiberry-dacplus
      _dotpi_audio_device_select_hifiberry
      ;;

    'hifiberry dac2 hd')
      dtoverlay=hifiberry-dacplushd
      _dotpi_audio_device_select_hifiberry
      ;;

    'hifiberry dac+ adc')
      dtoverlay=hifiberry-dacplusadc
      _dotpi_audio_device_select_hifiberry
      ;;

    'hifiberry dac+ adc pro')
      dtoverlay=hifiberry-dacplusadcpro
      _dotpi_audio_device_select_hifiberry
      ;;

    'hifiberry digi+')
      dtoverlay=hifiberry-digi
      _dotpi_audio_device_select_hifiberry
      ;;

    'hifiberry digi+ pro')
      dtoverlay=hifiberry-digi-pro
      _dotpi_audio_device_select_hifiberry
      ;;

    'hifiberry amp+')
      dtoverlay=hifiberry-amp
      _dotpi_audio_device_select_hifiberry
      ;;

    'hifiberry amp3')
      dtoverlay=hifiberry-amp3
      _dotpi_audio_device_select_hifiberry
      ;;

    ####### Ultimate Ears (UE)

    'ue boom 2'|'ue boom 3'|'ue megaboom 2'|'ue megaboom 3')
      _dotpi_audio_device_select_bluetooth
      ;;


    ########### Unknown device

    *) # other
      _dotpi_usage
      dotpi_echo_error "Unknown audio device model: ${model}"
      return 1
      ;;

  esac

  # use xargs to unquote value
  model_project="$(dotpi_configuration_read \
                     --file "${DOTPI_ROOT}/etc/dotpi_environment_project.bash" \
                     --key dotpi_audio_device \
                     | xargs)"


  if [[ "$model_normalised" == "$(dotpi_audio_device_model_normalise "$model_project")" ]] ; then
    # no need to update environment
    return 0;
  fi

  dotpi_echo_warning 'Audio device model is specific to this instance'

  # comment setting in project
  dotpi_configuration_comment --file "${DOTPI_ROOT}/etc/dotpi_environment_project.bash" \
                            --key dotpi_audio_device

  # escape double-quote for now, to quote when writing later
  model_value="$(echo "$model" | dotpi_sed 's/"/\\"/g')"

  # write changed setting in instance
  # be sure to quote value
  dotpi_configuration_write --file "${DOTPI_ROOT}/etc/dotpi_environment_instance.bash" \
                            --key dotpi_audio_device \
                            --value \""${model_value}"\"
)

_dotpi_audio_device_jackd_set_configuration() (
  model="$1"
  (cd "${DOTPI_ROOT}/share/jackd" && ln -s -f "dotpi_jackd_${model}.bash" 'dotpi_jackd.bash') || {
    dotpi_echo_error "Unable to change jackd configuration to ${model}"
    return 1
  }

  # we can change audio device in a temporary file-system, too
  if dotpi_system_is_raspberry_pi ; then
    dotpi_echo_warning "Restart jackd service"
    service='jackd'
    systemctl is-active "$service" > /dev/null 2>&1 \
      && systemctl restart "$service" || {
        dotpi_echo_warning "systemctl unable to restart service ${service}"
      }
fi
)

_dotpi_audio_device_disable_all() (
  exception_family="$1"

  if [[ "$exception_family" = "" ]] ; then
    dotpi_echo_info "Disabling all audio devices"
  else
    dotpi_echo_info "Disabling all audio devices except ${exception_family}"
  fi

  if [[ ! "$exception_family" = "headphones" ]] ; then
    _dotpi_audio_device_disable_headphones
  fi

  if [[ ! "$exception_family" = "hdmi" ]] ; then
    _dotpi_audio_device_disable_hdmi
  fi

  if [[ ! "$exception_family" = "raspberry_pi" ]] ; then
    _dotpi_audio_device_disable_raspberry_pi
  fi

  if [[ ! "$exception_family" = "hifiberry" ]] ; then
    _dotpi_audio_device_disable_hifiberry
  fi

)

_dotpi_audio_device_select_headphones() (
  dotpi_echo_info "Installing Headphones (default) audio device"

  _dotpi_audio_device_disable_all headphones

  # un-comment  dtparam=audio as it must be set first
  # (setting at the end the the file fails)
  pattern="$(dotpi_configuration_get_pattern --prefix "# dtparam=audio")"
  perl -pe "s/${pattern}/"'dtparam=audio=on/' -i -- "$config_file"

  _dotpi_audio_device_jackd_set_configuration "headphones"
)

_dotpi_audio_device_select_bluetooth() (
  _dotpi_audio_device_disable_all bluetooth

  _dotpi_audio_device_jackd_set_configuration "bluetooth"
)

_dotpi_audio_device_select_raspberry_pi() (
  dotpi_echo_info "Configuring Raspberry Pi audio device '${model}'"

  _dotpi_audio_device_disable_all raspberry_pi

  mkdir -p "$(dirname -- "$config_file")"
  cat >> "$config_file" << EOF

# dotpi: overlay for audio device '${model}'
dtoverlay=${dtoverlay}

EOF

  _dotpi_audio_device_jackd_set_configuration "hifiberry"
)


_dotpi_audio_device_select_hifiberry() (
  dotpi_echo_info "Configuring HiFiBerry audio device '${model}'"

  _dotpi_audio_device_disable_all hifiberry

  mkdir -p "$(dirname -- "$config_file")"
  cat >> "$config_file" << EOF

# dotpi: overlay for audio device '${model}'
dtoverlay=${dtoverlay}

EOF

  _dotpi_audio_device_jackd_set_configuration "hifiberry"
)

_dotpi_audio_device_disable_headphones() (
  dotpi_echo_info "Disabling headphones"
  # disable internal audio device
  dotpi_configuration_comment --file "$config_file" --key 'dtparam=audio'
)

_dotpi_audio_device_disable_hdmi() (
  dotpi_echo_info "Disabling HDMI audio"
  # disable HDMI audio

  # new systems
  pattern="$(dotpi_configuration_get_pattern --prefix "dtoverlay=vc4-kms-v3d")"
  perl -pe "s/${pattern}/"'${1}${2},noaudio/' -i -- "$config_file"

  # old systems
  pattern="$(dotpi_configuration_get_pattern --prefix "dtoverlay=vc4-fkms-v3d")"
  perl -pe "s/${pattern}/"'${1}${2},audio=off/' -i -- "$config_file"
)

_dotpi_audio_device_disable_raspberry_pi() (
  dotpi_echo_info "Disabling Raspberry Pi audio"

  # disable hifiberry
  pattern="$(dotpi_configuration_get_pattern --prefix "dtoverlay=rpi-")"
  perl -pe "s/${pattern}/"'${1}# ${2}${3}/' -i -- "$config_file"
)

_dotpi_audio_device_disable_hifiberry() (
  dotpi_echo_info "Disabling HiFiBerry audio"

  # disable hifiberry
  pattern="$(dotpi_configuration_get_pattern --prefix "dtoverlay=hifiberry-")"
  perl -pe "s/${pattern}/"'${1}# ${2}${3}/' -i -- "$config_file"
)

_dotpi_audio_device_volume_set_alsa() (
  amixer -- sset "$control" "$volume"
  alsactl store

  if [[ "$volume" ==  "$dotpi_audio_volume" ]] ; then
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
                            --value "$volume"
)

# set and store volume for the current audio device
dotpi_audio_device_volume_set() (
  volume="$1"

  model="$dotpi_audio_device"
  # lowercase everything
  model_normalised="$(dotpi_audio_device_model_normalise "$model")"

  case "$model_normalised" in

    ####### Generic devices

    'headphones')
      control='PCM'
      _dotpi_audio_device_volume_set_alsa
      ;;

    'bluetooth')
      dotpi_audio_bluetooth_destination_volume_set "$volume"
      ;;


    ####### Specific devices

    # HiFiBerry
    # Cf. https://www.hifiberry.com/docs/archive/mixer-controls-on-the-hifiberry-boards/


    'hifiberry dac+ dsp'|'hifiberry dac+ rtc'|'hifiberry dac+ standard'|'hifiberry amp2'|'hifiberry dac+ adc'|'hifiberry dac+ adc pro'|'hifiberry amp3')
      control='Digital'
      _dotpi_audio_device_volume_set_alsa
      ;;

    'hifiberry dac2 hd')
      control='DAC'
      _dotpi_audio_device_volume_set_alsa
      ;;

    'hifiberry amp+')
      control='Master'
      _dotpi_audio_device_volume_set_alsa
      ;;

    ####### Ultimate Ears (UE)

    'ue boom 2'|'ue boom 3'|'ue megaboom 2'|'ue megaboom 3')
      dotpi_audio_bluetooth_destination_volume_set "$volume"
      ;;

    ########### Unknown device

    *) # other
      dotpi_echo_error "Unable to set volume for unknown audio device model: ${model}"
      return 1
      ;;


  esac
)

# restore volume for the current audio device
dotpi_audio_device_volume_init() (
  if [[ -z "$dotpi_audio_volume" ]] ; then
    dotpi_echo_warning "dotpi_audio_volume not set, keeping default volume"
    return 0
  fi

  destination_volume="$dotpi_audio_volume"
  dotpi_audio_device_volume_set "$destination_volume"
)


