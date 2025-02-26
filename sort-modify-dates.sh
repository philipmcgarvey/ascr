#!/bin/bash

# updates all files last modified dates in current directory so that a last-modified sort gives same results as alphabetical sort

# Get the most recent modification time in the directory
latest_time=$(ls -lt --time=modify | awk 'NR==2 {print $6, $7, $8}')
latest_timestamp=$(date -d "$latest_time" +%s)

# Sort files alphabetically and update timestamps
counter=0
for file in $(ls -1 | sort); do
    if [[ -f "$file" ]]; then
        new_time=$((latest_timestamp + counter))
        touch -d "@${new_time}" "$file"
        ((counter++))
    fi
done

