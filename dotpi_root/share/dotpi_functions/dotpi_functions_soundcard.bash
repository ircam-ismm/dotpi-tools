#!/bin/bash

_dotpi_soundcard_get_options() {

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

dotpi_soundcard_model_normalise() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

dotpi_soundcard_select() (
  # sub-shell to keep everything local (functions and variables)

  _dotpi_command="$(basename -- "${FUNCNAME[0]:-"$0"}")"
  _dotpi_usage() {
    echo "Usage: ${_dotpi_command} --model <model> --config <config_file_path>"
  }

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  model=
  config_file=

  if ! _dotpi_soundcard_get_options "${@}" ; then
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
  model_normalised="$(dotpi_soundcard_model_normalise "$model")"

  case "$model_normalised" in

    # HiFiBerry
    # Cf. https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/

    'hifiberry dac for raspberry pi 1'|'hifiberry dac+ light'|'hifiberry dac zero'|'hifiberry miniamp'|'hifiberry beocreate'|'hifiberry dac+ dsp'|'hifiberry dac+ rtc')
      dtoverlay=hifiberry-dac
      _dotpi_soundcard_select_hifiberry
      ;;

    'hifiberry dac+ standard'|'hifiberry pro'|'hifiberry amp2')
      dtoverlay=hifiberry-dacplus
      _dotpi_soundcard_select_hifiberry
      ;;

    'hifiberry dac2 hd')
      dtoverlay=hifiberry-dacplushd
      _dotpi_soundcard_select_hifiberry
      ;;

    'hifiberry dac+ adc')
      dtoverlay=hifiberry-dacplusadc
      _dotpi_soundcard_select_hifiberry
      ;;

    'hifiberry dac+ adc pro')
      dtoverlay=hifiberry-dacplusadcpro
      _dotpi_soundcard_select_hifiberry
      ;;

    'hifiberry digi+')
      dtoverlay=hifiberry-digi
      _dotpi_soundcard_select_hifiberry
      ;;

    'hifiberry digi+ pro')
      dtoverlay=hifiberry-digi-pro
      _dotpi_soundcard_select_hifiberry
      ;;

    'hifiberry amp+')
      dtoverlay=hifiberry-amp
      _dotpi_soundcard_select_hifiberry
      ;;

    'hifiberry amp3')
      dtoverlay=hifiberry-amp3
      _dotpi_soundcard_select_hifiberry
      ;;

    headphones)
      _dotpi_soundcard_select_headphones
      ;;

    default)
      dotpi_echo_warning "Not installing a specific soundcard, keeping defaults"
      ;;

    none)
      _dotpi_soundcard_disable_all
      ;;

    -?*) # Unknown
      _dotpi_usage
      dotpi_echo_error "Unknown soundcard model: ${model}"
      return 1
      ;;

  esac

  if [[ "$model_normalised" == "$(dotpi_soundcard_model_normalise "$dotpi_soundcard")" ]] ; then
    # no need to update environment
    return 0;
  fi

  # comment setting in project
  dotpi_configuration_comment --file "${DOTPI_ROOT}/etc/dotpi_environment_project.bash" \
                            --key dotpi_soundcard


  model_value="$(echo "$model" | dotpi_sed 's/"/\\"/g')"

  # write changed setting in instance
  dotpi_configuration_write --file "${DOTPI_ROOT}/etc/dotpi_environment_instance.bash" \
                            --key dotpi_soundcard \
                            --value \""${model_value}"\"
)

_dotpi_soundcard_jackd_set_configuration() (
  model="$1"
  (cd "${DOTPI_ROOT}/share/jackd" && ln -s -f "dotpi_jackd_${model}.bash" 'dotpi_jackd.bash') || {
    dotpi_echo_error "Unable to change jackd configuration to ${model}"
    return 1
  }

  # we can change soundcard in a temporary file-system, too
  if dotpi_system_is_raspberry_pi ; then
    dotpi_echo_warning "Restart jackd service"
    service='jackd'
    systemctl is-active "$service" > /dev/null 2>&1 \
      && systemctl restart "$service" || {
        dotpi_echo_warning "systemctl unable to restart service ${service}"
      }
fi
)

_dotpi_soundcard_disable_all() (
  dotpi_echo_info "Disabling all sound-cards"

  _dotpi_soundcard_disable_headphones
  _dotpi_soundcard_disable_hdmi
  _dotpi_soundcard_disable_hifiberry
)

_dotpi_soundcard_select_headphones() (
  dotpi_echo_info "Installing Headphones (default) sound-card"

  _dotpi_soundcard_disable_hdmi
  _dotpi_soundcard_disable_hifiberry

  # un-comment  dtparam=audio as it must be set first
  # (setting at the end the the file fails)
  pattern="$(dotpi_configuration_get_pattern --prefix "# dtparam=audio")"
  perl -pe "s/${pattern}/"'dtparam=audio=on/' -i "$config_file"

  _dotpi_soundcard_jackd_set_configuration "headphones"
)

_dotpi_soundcard_select_hifiberry() (
  dotpi_echo_info "Configuring HiFiBerry sound-card '${model}'"

  _dotpi_soundcard_disable_headphones
  _dotpi_soundcard_disable_hdmi
  _dotpi_soundcard_disable_hifiberry

  mkdir -p "$(dirname -- "$config_file")"
  cat >> "$config_file" << EOF

# dotpi: overlay for soundcard '${model}'
dtoverlay=${dtoverlay}

EOF

  _dotpi_soundcard_jackd_set_configuration "hifiberry"
)

_dotpi_soundcard_disable_headphones() (
  # disable internal soundcard
  dotpi_configuration_comment --file "$config_file" --key 'dtparam=audio'
)

_dotpi_soundcard_disable_hdmi() (
  # disable HDMI audio

  # new systems
  pattern="$(dotpi_configuration_get_pattern --prefix "dtoverlay=vc4-kms-v3d")"
  perl -pe "s/${pattern}/"'${1}${2},noaudio/' -i "$config_file"

  # old systems
  pattern="$(dotpi_configuration_get_pattern --prefix "dtoverlay=vc4-fkms-v3d")"
  perl -pe "s/${pattern}/"'${1}${2},audio=off/' -i "$config_file"
)

_dotpi_soundcard_disable_hifiberry() (
  # disable hifiberry
  pattern="$(dotpi_configuration_get_pattern --prefix "dtoverlay=hifiberry-")"
  perl -pe "s/${pattern}/"'${1}# ${2}${3}/' -i "$config_file"
)
