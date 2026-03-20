#!/usr/bin/env bash

# --------------------------------------------------
# monitor.sh
# Real-time Linux System Monitoring Dashboard
# --------------------------------------------------

set -uo pipefail


# --------------------------------------------------
# Load Configuration
# --------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.cfg"

mkdir -p "${SCRIPT_DIR}/${LOG_DIR}"
mkdir -p "${SCRIPT_DIR}/${REPORT_DIR}"


# --------------------------------------------------
# ANSI Color Constants
# --------------------------------------------------

RST="\033[0m"
BOLD="\033[1m"

RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"

BG_RED="\033[41m"
BG_YELLOW="\033[43m"
BG_GREEN="\033[42m"


# --------------------------------------------------
# Helper Functions
# --------------------------------------------------

color_by_threshold() {
    local value=$1
    local warn=$2
    local crit=$3

    if (( $(echo "$value >= $crit" | bc -l) )); then
        echo "$RED"
    elif (( $(echo "$value >= $warn" | bc -l) )); then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}


status_label() {
    local value=$1
    local warn=$2
    local crit=$3

    if (( $(echo "$value >= $crit" | bc -l) )); then
        echo -e "${BG_RED} CRITICAL ${RST}"
    elif (( $(echo "$value >= $warn" | bc -l) )); then
        echo -e "${BG_YELLOW} WARNING ${RST}"
    else
        echo -e "${BG_GREEN} NORMAL ${RST}"
    fi
}


draw_bar() {

    local percent=$1
    local width=30

    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))

    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
}


# --------------------------------------------------
# Metric Collection Functions
# --------------------------------------------------

get_cpu_usage() {

    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

    idle1=$((idle + iowait))
    total1=$((user + nice + system + idle + iowait + irq + softirq + steal))

    sleep 1

    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

    idle2=$((idle + iowait))
    total2=$((user + nice + system + idle + iowait + irq + softirq + steal))

    idle_delta=$((idle2 - idle1))
    total_delta=$((total2 - total1))

    usage=$(( (100 * (total_delta - idle_delta)) / total_delta ))

    echo "$usage"
}


get_memory_usage() {

    mem_total=$(free | awk '/Mem:/ {print $2}')
    mem_used=$(free | awk '/Mem:/ {print $3}')

    percent=$(( mem_used * 100 / mem_total ))

    echo "$percent"
}


get_disk_usage() {

    usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

    echo "$usage"
}


get_load_average() {

    awk '{print $1}' /proc/loadavg
}


get_disk_io() {

    read read_kb write_kb < <(iostat -d 1 2 | awk 'NR>6 {r+=$3; w+=$4} END {print r, w}')

    echo "${read_kb}|${write_kb}"
}


get_network_connections() {

    ss -tun | grep ESTAB | wc -l
}


get_network_speed() {

    iface=$(ip route | awk '/default/ {print $5}')

    rx1=$(cat /sys/class/net/$iface/statistics/rx_bytes)
    tx1=$(cat /sys/class/net/$iface/statistics/tx_bytes)

    sleep 1

    rx2=$(cat /sys/class/net/$iface/statistics/rx_bytes)
    tx2=$(cat /sys/class/net/$iface/statistics/tx_bytes)

    rx_rate=$(( (rx2 - rx1) / 1024 ))
    tx_rate=$(( (tx2 - tx1) / 1024 ))

    echo "${rx_rate}|${tx_rate}"
}


get_error_rate() {

    errors=$(journalctl --since "5 min ago" 2>/dev/null | grep -i error | wc -l)

    echo "$errors"
}


get_top_processes() {

    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
}


get_tcp_retransmissions() {

    netstat -s | awk '/retransmit/ {print $1; exit}'
}

# --------------------------------------------------
# Alert Trigger Function
# --------------------------------------------------

trigger_alerts() {

    bash "${SCRIPT_DIR}/alerts.sh" "$cpu" "$mem" "$disk" "$load" &

}


# --------------------------------------------------
# Health Logging
# --------------------------------------------------

log_health() {

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$timestamp CPU=$cpu MEM=$mem DISK=$disk LOAD=$load" >> "${SCRIPT_DIR}/${HEALTH_LOG}"

}



# --------------------------------------------------
# Dashboard Renderer
# --------------------------------------------------

render_dashboard() {

    clear

    echo "=============================================="
    echo "        Linux Monitoring Dashboard"
    echo "=============================================="
    echo

    cpu=$(get_cpu_usage)
    mem=$(get_memory_usage)
    disk=$(get_disk_usage)
    load=$(get_load_average)
	
    trigger_alerts
    log_health


    cpu_color=$(color_by_threshold "$cpu" "$CPU_WARN" "$CPU_CRIT")
    mem_color=$(color_by_threshold "$mem" "$MEMORY_WARN" "$MEMORY_CRIT")
    disk_color=$(color_by_threshold "$disk" "$DISK_WARN" "$DISK_CRIT")

    cpu_status=$(status_label "$cpu" "$CPU_WARN" "$CPU_CRIT")
    mem_status=$(status_label "$mem" "$MEMORY_WARN" "$MEMORY_CRIT")
    disk_status=$(status_label "$disk" "$DISK_WARN" "$DISK_CRIT")

    echo -e "CPU Usage : ${cpu_color}${cpu}%${RST}"
    draw_bar "$cpu"
    echo "Status: $cpu_status"
    echo

    echo -e "Memory Usage : ${mem_color}${mem}%${RST}"
    draw_bar "$mem"
    echo "Status: $mem_status"
    echo

    echo -e "Disk Usage : ${disk_color}${disk}%${RST}"
    draw_bar "$disk"
    echo "Status: $disk_status"
    echo

    echo "Load Average: $load"
    echo

    echo "Top Processes:"
    get_top_processes
}


# --------------------------------------------------
# Main Monitoring Loop
# --------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    trap "echo -e '\n${GREEN}Dashboard stopped.${RST}'; exit 0" SIGINT SIGTERM

    MODE="${1:-}"

    if [[ "$MODE" == "--watch" ]]; then
        while true
        do
            render_dashboard
            sleep "${REFRESH_INTERVAL:-5}"
        done
    else
        render_dashboard
    fi

fi
