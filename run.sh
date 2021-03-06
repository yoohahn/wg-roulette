#!/bin/bash
FORCE_NEW=${FORCE_NEW:-0}
WG_PATH="/etc/wireguard"
[ "$DEBUG" ] && WG_PATH=$PWD
LOG_FILE="/var/log/wg-roulette.log"
WG_INTERFACE=${WG_INTERFACE:-wg0}
WG_LOCATION="$WG_PATH/$WG_INTERFACE.conf"
WG_CONFIG_FOLDER=${WG_CONFIG_FOLDER:-conf}
## My VPN provider has an internal ip that I can ping to verify that my tunnel is active.
PING_IP=${PING_IP:-10.64.0.1}
RANDOM_CONFIG=""

[ "$DEBUG" ] && WG_CONFIG_FOLDER=$WG_CONFIG_FOLDER.example

killTunnel(){
  HAS_WG_INTERFACE=$(ifconfig | grep $WG_INTERFACE)
  if [ "$HAS_WG_INTERFACE" != "" ]; then
    wg-quick down $WG_INTERFACE 2> /dev/null
    sleep 2
  fi
}

killCurrentAndPickANewConfig() {
  killTunnel
  RANDOM_CONFIG=$(ls $WG_CONFIG_FOLDER | shuf -n 1)
  cp $WG_CONFIG_FOLDER/$RANDOM_CONFIG $WG_LOCATION
  sleep 1
  wg-quick up $WG_INTERFACE
  sleep 2
}

validateRuns=0

start(){
  validateRuns=$((validateRuns+1))
  if [ $validateRuns -gt 5 ]; then
    echo "`date` Failed to start '$WG_INTERFACE'" >> $LOG_FILE 2> /dev/null
    exit 0
  fi

  idx=0
  HAS_WG_INTERFACE=$(ifconfig | grep $WG_INTERFACE)
  if [ "$HAS_WG_INTERFACE" != "" ]; then
    echo "`date` HAS_WG_INTERFACE" >> $LOG_FILE 2> /dev/null
    while [ $idx -lt 2 ]; do
      if /bin/ping -c 1 -I $WG_INTERFACE $PING_IP; then
        [ "$RANDOM_CONFIG" ] && echo "`date` Successfully started with '$RANDOM_CONFIG'" >> $LOG_FILE 2> /dev/null
        exit 0
      fi
      idx=$((idx+1))
    done
  else
    [ "$RANDOM_CONFIG" ] && echo "`date` Failed to start with '$RANDOM_CONFIG'" >> $LOG_FILE 2> /dev/null
  fi

  killCurrentAndPickANewConfig
  start
}

touch $LOG_FILE 2> /dev/null
if [ "$DEBUG" ]; then
  killCurrentAndPickANewConfig
  exit 0
else
  [ "$FORCE_NEW" = "1" ] && killCurrentAndPickANewConfig
  start
fi
