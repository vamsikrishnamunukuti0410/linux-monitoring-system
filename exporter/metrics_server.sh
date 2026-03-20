#!/usr/bin/env bash

PORT=9100

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting the HTTP server on port.."

while true; do
  {
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n"
    bash "${SCRIPT_DIR}/metrics.sh"
  } | nc -l -p $PORT -q 1
done
