#!/usr/bin/bash
# self_heal.sh — Service auto-restart monitor

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.cfg"

mkdir -p "${SCRIPT_DIR}/${LOG_DIR}"

LOG_FILE="${SCRIPT_DIR}/${SELF_HEAL_LOG}"

log_msg() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Ensure systemctl exists
if ! command -v systemctl >/dev/null 2>&1; then
    log_msg "systemctl not found. This script requires systemd."
    exit 1
fi

for service in $CRITICAL_SERVICES; do

    # Check if service exists
    if ! systemctl list-unit-files | grep -q "^${service}\.service"; then
        log_msg "Service $service not found. Skipping."
        continue
    fi

    # Check if service is running
    if systemctl is-active --quiet "$service"; then
        log_msg "Service $service is running."
        continue
    fi

    log_msg "Service $service is DOWN. Attempting restart."

    retry=1
    success=false

    while [ $retry -le "$MAX_RESTART_RETRIES" ]; do

        log_msg "Restart attempt $retry for $service"

        sudo systemctl restart "$service"
        sleep 2

        if systemctl is-active --quiet "$service"; then
            log_msg "Service $service successfully restarted."
            success=true
            break
        fi

        retry=$((retry + 1))

    done

    if [[ "$success" = false ]]; then
        log_msg "CRITICAL: Failed to restart $service after $MAX_RESTART_RETRIES attempts."

        if [[ "$EMAIL_ENABLED" == "true" ]]; then
            if command -v mail >/dev/null 2>&1; then
                echo "Service $service failed to restart on $(hostname)" | \
                mail -s "${EMAIL_SUBJECT_PREFIX} Service Failure" "$EMAIL_RECIPIENT"
            fi
        fi
    fi

done
