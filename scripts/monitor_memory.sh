#!/bin/bash

threshold=90  # Set your desired memory usage threshold (percentage)

memory_usage=$(free | awk '/Mem/{printf("%.2f"), $3/$2*100}')

if (( $(echo "$memory_usage > $threshold" | bc -l) )); then
    systemctl --user restart VSCodeServer
    echo "VSCode Server restarted due to high memory usage (${memory_usage}%)"
fi
