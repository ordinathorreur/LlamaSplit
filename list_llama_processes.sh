#!/usr/bin/env bash
# Enhanced list of llama processes with color coding and summary

PROC="llama-server"

# Check for existence
if ! pgrep -f "$PROC" > /dev/null; then
  echo "No $PROC processes running."
  exit 0
fi

# Header
printf "%-6s %-6s %-6s %-6s %s\n" "PID" "PPID" "CPU%" "MEM%" "CMD"

# List processes sorted by CPU, color high usage
ps -C "$PROC" -o pid=,ppid=,pcpu=,pmem=,cmd= | \
  sort -k3,3nr | \
  awk '
BEGIN {FS=" "; OFS="\t"}
{
  pid=$1; ppid=$2; cpu=$3; mem=$4; cmd=$5
  if (cpu+0 > 10) color="\033[31m"   # red for >10% CPU
  else if (cpu+0 > 5) color="\033[33m" # yellow for >5% CPU
  else color="\033[32m"               # green otherwise
  printf "%s%-6s%s %-6s %-6s %-6s %s\n", color, pid, "\033[0m", ppid, cpu, mem, cmd
}
'

# Summary
echo
echo "Total $PROC processes: $(pgrep -f "$PROC" | wc -l)"
echo "Total CPU usage: $(ps -C "$PROC" -o pcpu= | awk '{sum+=$1} END{print sum}')%"
echo "Total MEM usage: $(ps -C "$PROC" -o pmem= | awk '{sum+=$1} END{print sum}')%"
# GPU summary
if command -v nvidia-smi > /dev/null; then
  # Overall GPU utilisation
  gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{sum+=$1} END{print sum/NR}')
  echo "Total GPU utilisation: $gpu_util%"

  # Total VRAM utilisation
mem_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | awk '{sum+=$1} END{print sum}')
mem_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | awk '{sum+=$1} END{print sum}')
if [ "$mem_total" -gt 0 ]; then
  vram_pct=$(awk -v used=$mem_used -v total=$mem_total 'BEGIN{printf "%.2f", (used/total)*100}')
else
  vram_pct="N/A"
fi
echo "Total VRAM utilisation: $vram_pct%"
fi
