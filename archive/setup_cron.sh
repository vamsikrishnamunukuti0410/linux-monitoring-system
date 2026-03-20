#!/usr/bin/env bash
# setup_cron.sh — Install cron jobs for monitoring system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CRON_START="# LINUX-MONITORING-SYSTEM-START"
CRON_END="# LINUX-MONITORING-SYSTEM-END"

CRON_JOBS=$(cat <<EOF
$CRON_START
*/5 * * * * bash ${SCRIPT_DIR}/alerts.sh
*/5 * * * * bash ${SCRIPT_DIR}/self_heal.sh
59 23 * * * bash ${SCRIPT_DIR}/report.sh
0 0 * * * bash ${SCRIPT_DIR}/log_rotation.sh
0 2 * * 0 bash ${SCRIPT_DIR}/maintenance.sh
0 3 * * 0 bash ${SCRIPT_DIR}/security_update.sh
$CRON_END
EOF
)

# Remove old entries
( crontab -l 2>/dev/null | sed "/$CRON_START/,/$CRON_END/d" ) | crontab -

# Install new cron jobs
( crontab -l 2>/dev/null; echo "$CRON_JOBS" ) | crontab -

echo "Cron jobs installed successfully."

echo
echo "Installed schedules:"
echo "alerts.sh + self_heal.sh → every 5 minutes"
echo "report.sh → daily at 11:59 PM"
echo "log_rotation.sh → daily at midnight"
echo "maintenance.sh → Sunday 2 AM"
echo "security_update.sh → Sunday 3 AM"

echo
echo "To remove these jobs later, run:"
echo "crontab -e and delete lines between:"
echo "$CRON_START"
echo "$CRON_END"
