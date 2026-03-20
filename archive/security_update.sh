#!/usr/bin/bash
# security_update.sh — Security-only patch installer

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.cfg"

mkdir -p "${SCRIPT_DIR}/${LOG_DIR}"

LOG_FILE="${SCRIPT_DIR}/${SECURITY_LOG}"

timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

log_msg() {
    echo "[$(timestamp)] $1" | tee -a "$LOG_FILE"
}

log_msg "Starting security update process..."

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
else
    log_msg "Cannot determine Linux distribution."
    exit 1
fi

UPDATE_OUTPUT=""

case "$DISTRO" in

    ubuntu|debian)
        log_msg "Detected Debian-based system"
        if command -v unattended-upgrade >/dev/null 2>&1; then
            UPDATE_OUTPUT=$(sudo unattended-upgrade -d 2>&1)
        else
            UPDATE_OUTPUT=$(sudo apt-get upgrade -y 2>&1)
        fi
        ;;

    rhel|centos|rocky|almalinux)
        log_msg "Detected RHEL-based system"
        if command -v dnf >/dev/null 2>&1; then
            UPDATE_OUTPUT=$(sudo dnf update --security -y 2>&1)
        else
            UPDATE_OUTPUT=$(sudo yum update --security -y 2>&1)
        fi
        ;;

    fedora)
        log_msg "Detected Fedora system"
        UPDATE_OUTPUT=$(sudo dnf update --security -y 2>&1)
        ;;

    *)
        log_msg "Unsupported distribution: $DISTRO"
        exit 1
        ;;

esac

# Log last part of update output
echo "$UPDATE_OUTPUT" | tail -n 20 >> "$LOG_FILE"

log_msg "Security update process completed."
