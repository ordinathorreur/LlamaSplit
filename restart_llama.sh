#!/usr/bin/env bash
# restart_llama_dual.sh
# This script stops any running Llama processes, waits for them to exit,
# logs the restart event, and then starts the dual‑GPU Llama servers.

set -euo pipefail

LOG_FILE="llama_restart.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] Restart initiated." | tee -a "$LOG_FILE"

# Stop existing Llama processes
echo "[$TIMESTAMP] Stopping existing Llama processes..." | tee -a "$LOG_FILE"
./stop_llama.sh 2>&1 | tee -a "$LOG_FILE" || true

# Wait until all llama processes have exited
echo "[$TIMESTAMP] Waiting for processes to terminate..." | tee -a "$LOG_FILE"
while pgrep -a llama > /dev/null; do
    sleep 1
done
echo "[$TIMESTAMP] All Llama processes terminated." | tee -a "$LOG_FILE"

# Start the servers
echo "[$TIMESTAMP] Starting Llama servers..." | tee -a "$LOG_FILE"
./start_llama.sh 2>&1 | tee -a "$LOG_FILE" &

echo "[$TIMESTAMP] Restart completed successfully." | tee -a "$LOG_FILE"
