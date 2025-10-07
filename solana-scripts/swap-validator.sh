#!/usr/bin/env bash
set -e
#set -x #debug
# ===[ helper logging ]===
log_step() {
  local msg="$1"
  echo -e "\e[34m[→]\e[0m $msg"
}

log_success() {
  echo -e "\e[32m[✔]\e[0m Success"
}

log_fail() {
  echo -e "\e[31m[✖]\e[0m Failed"
  exit 1
}

CONFIG_FILE="./swap.env"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file $CONFIG_FILE not found"
  exit 1
fi
source "$CONFIG_FILE"


# ===[ ssh options ]===
SSH_OPTS=(
  -p "${REMOTE_PORT}"
  -i "${LOCAL_SSH_KEY}"
  -o ControlMaster=auto
  -o ControlPath=/tmp/ssh-%r@%h:%p
  -o ControlPersist=yes
)


read -p "⚠️  Do you want to switch validator? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "❌ Canceled."
  exit 1
fi

# ===[ cleanup any existing master session ]===
log_step "Checking for existing SSH master connection..."
if ssh -O check -p "${REMOTE_PORT}" -i "${LOCAL_SSH_KEY}" -o ControlPath=/tmp/ssh-%r@%h:%p "${REMOTE_USER}@${REMOTE_HOST}" 2>/dev/null; then
  log_step "Closing existing SSH master connection..."
  if ssh -O exit -p "${REMOTE_PORT}" -i "${LOCAL_SSH_KEY}" -o ControlPath=/tmp/ssh-%r@%h:%p "${REMOTE_USER}@${REMOTE_HOST}"; then
    log_success
  else
    log_fail
  fi
else
  log_step "No existing master connection"
  log_success
fi


log_step "Establishing SSH master connection..."
ssh "${SSH_OPTS[@]}" -M -f -N "${REMOTE_USER}@${REMOTE_HOST}" || log_fail
trap 'ssh -O exit -p "${REMOTE_PORT}" -i "${LOCAL_SSH_KEY}" -o ControlPath=/tmp/ssh-%r@%h:%p "${REMOTE_USER}@${REMOTE_HOST}" 2>/dev/null || true' EXIT
log_success


#log_step "Remotely setting rights"
#ssh "${SSH_OPTS[@]}" "${REMOTE_USER}@${REMOTE_HOST}" "
#     sudo chown -R '${REMOTE_USER}':'${REMOTE_USER}' '${REMOTE_KEY_DIR}' && \
#     sudo chown -R '${REMOTE_USER}':'${REMOTE_USER}' /mnt/solana* "


log_step "Waiting for local restart window..."
if "${LOCAL_VALIDATOR_BIN}" -l "${LOCAL_LEDGER_DIR}" wait-for-restart-window --min-idle-time 2 --skip-new-snapshot-check; then
  log_success
else
  log_fail
fi

log_step "Setting local UNSTAKED identity and updating symlink..."
if  ln -sf "${LOCAL_UNSTAKED_ID}" "${LOCAL_ID_SYMLINK}" && \
   "${LOCAL_VALIDATOR_BIN}" -l "${LOCAL_LEDGER_DIR}" set-identity "${LOCAL_UNSTAKED_ID}"; then
  log_success
else
  log_fail
fi

log_step "Copying tower file to remote server via dd and SSH master connection..."
if dd if="${LOCAL_TOWER_FILE}" bs=4M | ssh "${SSH_OPTS[@]}" "${REMOTE_USER}@${REMOTE_HOST}" "dd of='${REMOTE_LEDGER_DIR}/$(basename "${LOCAL_TOWER_FILE}")' bs=4M"; then
  log_success
else
  log_fail
fi



log_step "Remotely setting STAKED identity and updating symlink..."
if ssh "${SSH_OPTS[@]}" "${REMOTE_USER}@${REMOTE_HOST}" "
     ln -sf '${REMOTE_STAKED_ID}' '${REMOTE_ID_SYMLINK}' && \
     '${REMOTE_VALIDATOR_BIN}' -l '${REMOTE_LEDGER_DIR}' set-identity --require-tower '${REMOTE_STAKED_ID}'"; then
  log_success
else
  log_fail
fi

echo -e "\e[1;32m[✓] All steps completed successfully\e[0m"

