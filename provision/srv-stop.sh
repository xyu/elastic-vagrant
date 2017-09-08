#!/bin/bash

# Make sure pid dir exists no matter what
mkdir -p /var/run/elastic

# Kill running Kibana and ES processes
PIDS=()
PIDS+=$( find /var/run/elastic -name *.pid )
for PID in $PIDS; do
  if [ -f $PID ]; then
    pkill -e --pidfile $PID
  fi
done
