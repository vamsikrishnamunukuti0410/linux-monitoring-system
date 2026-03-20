#!/usr/bin/env bash

# --------------------------------------------------
# alerts.sh
# Threshold Alert Monitoring
# --------------------------------------------------

set -uo pipefail


# --------------------------------------------------
# Load Configuration
# --------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.cfg"

mkdir -p "${SCRIPT_DIR}/${LOG_DIR}"

ALERT_FILE="${SCRIPT_DIR}/${ALERT_LOG}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')


# --------------------------------------------------
# Receive Metrics from monitor.sh
# --------------------------------------------------

CPU="${1:-0}"
MEM="${2:-0}"
DISK="${3:-0}"
LOAD="${4:-0}"


# --------------------------------------------------
# Alert storage array
# --------------------------------------------------

ALERTS_TRIGGERED=()


# --------------------------------------------------
# Threshold Check Function
# --------------------------------------------------

check_threshold() {

    local metric="$1"
    local value="$2"
    local warn="$3"
    local crit="$4"

    if (( $(echo "$value >= $crit" | bc -l) )); then

        msg="[$TIMESTAMP] CRITICAL: $metric = $value (warn=$warn, crit=$crit)"
        echo "$msg" >> "$ALERT_FILE"
        ALERTS_TRIGGERED+=("$msg")

    elif (( $(echo "$value >= $warn" | bc -l) )); then

        msg="[$TIMESTAMP] WARNING: $metric = $value (warn=$warn, crit=$crit)"
        echo "$msg" >> "$ALERT_FILE"
        ALERTS_TRIGGERED+=("$msg")

    fi
}


# --------------------------------------------------
# Run threshold checks
# --------------------------------------------------

check_threshold "CPU" "$CPU" "$CPU_WARN" "$CPU_CRIT"
check_threshold "MEMORY" "$MEM" "$MEMORY_WARN" "$MEMORY_CRIT"
check_threshold "DISK" "$DISK" "$DISK_WARN" "$DISK_CRIT"
check_threshold "LOAD" "$LOAD" "$LOAD_WARN" "$LOAD_CRIT"


# --------------------------------------------------
# Email Alert Notification (optional)
# --------------------------------------------------

send_email_alert() {

    local body="$1"

    if command -v mail >/dev/null 2>&1; then
        echo "$body" | mail -s "${EMAIL_SUBJECT_PREFIX} System Alert" "$EMAIL_RECIPIENT"

    elif command -v sendmail >/dev/null 2>&1; then
        {
            echo "Subject: ${EMAIL_SUBJECT_PREFIX} System Alert"
            echo "To: ${EMAIL_RECIPIENT}"
            echo "From: ${EMAIL_FROM}"
            echo
            echo "$body"
        } | sendmail -t
    fi
}


# --------------------------------------------------
# Send email if alerts occurred
# --------------------------------------------------

if [[ "$EMAIL_ENABLED" == "true" && ${#ALERTS_TRIGGERED[@]} -gt 0 ]]; then

    ALERT_BODY=$(printf "%s\n" "${ALERTS_TRIGGERED[@]}")

    send_email_alert "$ALERT_BODY"

fi
