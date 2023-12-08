# keep this
DOTPI_JACKD_ENVIRONMENT=(
  JACK_NO_AUDIO_RESERVATION=1
)

# warning: long option for -d (--driver) seems broken

# explicit outchannels (default is 0)

DOTPI_JACKD_ARGUMENTS=(
  --realtime
  --realtime-priority 95
  -d alsa
  --device hw:0
  --playback
  --period 1024
  --nperiods 2
  --rate 48000
  --inchannels 0
  --outchannels 2
)
