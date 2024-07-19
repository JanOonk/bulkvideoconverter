#!/bin/bash

ps -A

# Define the processes to kill in order
processes_to_kill=("sh" "runConvertVideo" "convertVideos.s" "ffmpeg" "sleep")

# Loop through each process and kill it
for process in "${processes_to_kill[@]}"; do
    # Find the PIDs of the processes and kill them
    pids=$(pgrep -x "$process")
    if [ -n "$pids" ]; then
        echo "Killing process: $process"
        echo "$pids" | xargs kill -9
    else
        echo "No process found for: $process"
    fi
done

sleep 1

ps -A
