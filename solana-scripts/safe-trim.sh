#!/bin/bash
#set -x
# Trim FS before mine slot.
# You can set cron job for it.

############ SETTINGS ############
# Path to solana binary
SOLANA_CLI="/root/.local/share/solana/install/active-release/bin/solana"
# Set your SOLANA_IDENTITY_PYBKEY or SOLANA_IDENTITY_KEYPAIR
SOLANA_IDENTITY_PUBKEY=""
SOLANA_IDENTITY_KEYPAIR="/root/solana/validator-keypair.json"
# How many slots in front of mine
SLOTS_LOOKAHEAD=20000
# Leave black to use local RPC
RPC_URL=""
##################################
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

if [ ! -f "$SOLANA_CLI" ]; then
    echo "Solana binary not found. Please set the full path."
    exit 1
fi

if [ -z "$SOLANA_IDENTITY_PUBKEY" ]; then
   SOLANA_IDENTITY_PUBKEY=$($SOLANA_CLI address -k $SOLANA_IDENTITY_KEYPAIR)
fi

if [ -z "$SOLANA_IDENTITY_PUBKEY" ]; then
   echo "Unable to determine validator pubkey. Please set SOLANA_IDENTITY_PUBKEY or SOLANA_IDENTITY_KEYPAIR."
   exit 1
fi

if [ -z "$RPC_URL" ]; then
   RPC_URL="http://127.0.0.1:8899"
fi

if [ ! -x "$SOLANA_CLI" ]; then
    log "ERROR: Solana CLI not found at $SOLANA_CLI"
    exit 1
fi

CURRENT_SLOT=$($SOLANA_CLI slot --url $RPC_URL 2>/dev/null)

if [ ! -n "$CURRENT_SLOT" ]; then
   log "ERROR: Failed to get CURRENT_SLOT"
    exit 1
fi

LEADER_SLOTS=$($SOLANA_CLI leader-schedule --url $RPC_URL | grep $SOLANA_IDENTITY_PUBKEY | awk '{print $1}')

if [ $? -eq 0 ] && [ ! -n "$LEADER_SLOTS" ]; then
    LEADER_SLOT=999999999999
elif [ -n "$LEADER_SLOTS" ]; then
     for SLOT in $LEADER_SLOTS; do
         if (( SLOT - CURRENT_SLOT > 0 && SLOT - CURRENT_SLOT < SLOTS_LOOKAHEAD )); then
             log "$NOW - Skipping TRIM: Leader slot detected soon (slot $SLOT)." 
             exit 0
          fi
     done
else 
    log "ERROR: Failed to get LEADER_SLOTS"
    exit 1
fi

log "Running TRIM..."
ionice -c3 nice -n19 fstrim -av 

if [ $? -eq 0 ]; then
    log "TRIM completed successfully." 
else
    log "ERROR: TRIM failed." 
fi
