#!/bin/bash

##
## Watchdog script for solana-monitor.sh
## It will be clear metrics file if solana-monitor.sh didn't update metrics more then timeout
##

########### CONFIG ############################################
#
# The directory output of the Prometheus metrics file
metricsFile="/var/lib/node_exporter/solana_validator_metrics.prom"
# Timeout after which to clear the metrics file if they are not updated
timeout_sec=120  
#
########### CONFIG ############################################

now=$(date +%s)

if [[ -f "$metricsFile" ]]; then
    ts=$(grep '^solana_validator_timeStamp' "$metricsFile" | awk '{print $2}')
    if [[ ! -z "$ts" ]]; then
        ts_sec=$((ts / 1000))
        age=$((now - ts_sec))

        if (( age > timeout_sec )); then
            echo  > "$metricsFile"
        fi
    fi
fi
