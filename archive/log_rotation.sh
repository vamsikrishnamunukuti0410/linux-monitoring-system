#!/usr/bin/bash
# log_rotation.sh — Log cleanup and compression

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.cfg"

LOG_PATH="${SCRIPT_DIR}/${LOG_DIR}"
REPORT_PATH="${SCRIPT_DIR}/${REPORT_DIR}"

mkdir -p "$LOG_PATH" "$REPORT_PATH"

timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

log_msg() {
    echo "[$(timestamp)] $1"
}

log_msg "Starting log rotation..."

# 1. Delete logs older than retention period
find "$LOG_PATH" -type f -mtime +"$LOG_RETENTION_DAYS" -print -delete

# 2. Compress logs larger than max size
for logfile in "$LOG_PATH"/*.log; do

    [ -e "$logfile" ] || continue

    size_bytes=$(stat -c%s "$logfile" 2>/dev/null || stat -f%z "$logfile")

    size_mb=$((size_bytes / 1024 / 1024))

    if (( size_mb >= LOG_MAX_SIZE_MB )); then
        log_msg "Compressing $logfile ($size_mb MB)"
        gzip "$logfile"
    fi

done

# 3. Prune excess rotated logs
for base in alerts health_history self_heal security_update; do

    files=$(ls -1t "$LOG_PATH"/${base}.log*.gz 2>/dev/null || true)

    count=0

    for file in $files; do
        count=$((count + 1))

        if (( count > MAX_ROTATED_FILES )); then
            log_msg "Removing old rotated log $file"
            rm -f "$file"
        fi
    done

done

# 4. Remove old reports
find "$REPORT_PATH" -type f -mtime +"$LOG_RETENTION_DAYS" -print -delete

log_msg "Log rotation complete."
