# keep this
DOTPI_JACKD_ENVIRONMENT=(
  JACK_NO_AUDIO_RESERVATION=1
)

# warning: long option for -d (--driver) seems broken

DOTPI_JACKD_ARGUMENTS=(
  --realtime
  --realtime-priority 95
  -d alsa
  --device hw:0,0
  --duplex
  --period 128
  --nperiods 2
  --rate 48000
)
