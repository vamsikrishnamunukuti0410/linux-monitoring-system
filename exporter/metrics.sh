#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "${SCRIPT_DIR}/../core" && pwd)"

source "${CORE_DIR}/monitor.sh"

cpu=$(get_cpu_usage)
mem=$(get_memory_usage)
disk=$(get_disk_usage)
load=$(get_load_average)
net_conn=$(get_network_connections)
errors=$(get_error_rate)
tcp_retrans=$(get_tcp_retransmissions)
disk_io=$(get_disk_io)
net_speed=$(get_network_speed)

read_io=$(echo "$disk_io" | cut -d'|' -f1)
write_io=$(echo "$disk_io" | cut -d'|' -f2)



echo "cpu_usage $cpu"
echo "memory_usage $mem"
echo "disk_usage $disk"
echo "load_average $load"
echo "network_connections $net_conn"
echo "error_rate $errors"
echo "tcp_retransmissions $tcp_retrans"
echo "disk_io_read $read_io"
echo "disk_io_write $write_io"
