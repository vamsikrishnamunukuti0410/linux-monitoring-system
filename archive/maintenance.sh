#!/usr/bin/bash
# maintenance.sh — Weekly system maintenance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.cfg"

LOG_FILE="${SCRIPT_DIR}/logs/maintenance.log"

mkdir -p "${SCRIPT_DIR}/${LOG_DIR}"

log_msg() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

log_msg "Starting weekly maintenance..."

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then

    log_msg "Running apt-get updates"
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get autoremove -y

elif command -v yum >/dev/null 2>&1; then

    log_msg "Running yum updates"
    sudo yum update -y
    sudo yum autoremove -y

elif command -v dnf >/dev/null 2>&1; then

    log_msg "Running dnf updates"
    sudo dnf update -y
    sudo dnf autoremove -y

elif command -v pacman >/dev/null 2>&1; then

    log_msg "Running pacman updates"
    sudo pacman -Syu --noconfirm

else

    log_msg "No supported package manager found"

fi

# Cleanup temporary files
log_msg "Cleaning temporary files"

sudo find /tmp -type f -mtime +7 -delete
sudo find /var/tmp -type f -mtime +7 -delete

# Clean thumbnail cache if present
if [ -d "$HOME/.cache/thumbnails" ]; then
    rm -rf "$HOME/.cache/thumbnails/"*
fi

# Vacuum journal logs (keep 7 days)
if command -v journalctl >/dev/null 2>&1; then
    sudo journalctl --vacuum-time=7d
fi

# Run log rotation if script exists
if [ -x "${SCRIPT_DIR}/log_rotation.sh" ]; then
    log_msg "Running log rotation"
    bash "${SCRIPT_DIR}/log_rotation.sh"
fi

log_msg "Weekly maintenance completed."
