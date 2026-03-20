#!/usr/bin/bash
# report.sh — Daily system report generator

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.cfg"

mkdir -p "${SCRIPT_DIR}/${REPORT_DIR}"

TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
REPORT_FILE="${SCRIPT_DIR}/${REPORT_DIR}/system_report_${TIMESTAMP}.txt"

get_error_count() {
    if command -v journalctl >/dev/null 2>&1; then
        journalctl --since "24 hours ago" | grep -i error | wc -l
    elif [ -f /var/log/syslog ]; then
        grep -i error /var/log/syslog | wc -l
    else
        echo "0"
    fi
}

get_tcp_stats() {
    if [ -f /proc/net/snmp ]; then
        awk '/Tcp:/ {print $13}' /proc/net/snmp | tail -1
    elif command -v netstat >/dev/null 2>&1; then
        netstat -s | grep -i retransmit | wc -l
    else
        echo "N/A"
    fi
}

{
echo "==============================================="
echo "        Linux Monitoring Daily Report"
echo "==============================================="
echo
echo "Generated at: $(date)"
echo "Hostname: $(hostname)"
echo

echo "----- System Uptime -----"
uptime
echo

echo "----- CPU Statistics -----"
if command -v mpstat >/dev/null 2>&1; then
    mpstat
else
    top -bn1 | grep "Cpu"
fi
echo

echo "----- Memory Statistics -----"
free -h
echo

echo "----- Disk Statistics -----"
df -h
echo

echo "----- Top 5 Processes (CPU) -----"
ps aux --sort=-%cpu | head -6
echo

echo "----- Load Average -----"
cat /proc/loadavg
echo

echo "----- Network Connections -----"
if command -v ss >/dev/null 2>&1; then
    ss -tun | wc -l
else
    netstat -an | grep ESTABLISHED | wc -l
fi
echo

echo "----- Error Summary (24h) -----"
get_error_count
echo

echo "----- TCP Retransmissions -----"
get_tcp_stats
echo

echo "----- Alert Summary (Today) -----"
if [ -f "${SCRIPT_DIR}/${ALERT_LOG}" ]; then
    grep "$(date '+%Y-%m-%d')" "${SCRIPT_DIR}/${ALERT_LOG}" || echo "No alerts today"
else
    echo "Alert log not found"
fi
echo

} > "$REPORT_FILE"

ARCHIVE_FILE="${REPORT_FILE}.gz"

if command -v gzip >/dev/null 2>&1; then
    gzip -c "$REPORT_FILE" > "$ARCHIVE_FILE"
fi

if [[ "${EMAIL_ENABLED}" == "true" ]]; then
    if command -v mail >/dev/null 2>&1; then
        mail -s "Daily System Report $(hostname)" -a "$ARCHIVE_FILE" "$EMAIL_RECIPIENT" < "$REPORT_FILE"
    fi
fi

echo "Report generated: $REPORT_FILE"
