#!/bin/bash

# Define source and destination directories
SRC_DIR="/storage/emulated/0/DCIM/Camera"
DEST_DIR="./audio"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Find the most recently modified .mp4 file and copy it
latest_mp4=$(ls -t "$SRC_DIR"/*.mp4 2>/dev/null | head -n 1)

if [[ -n "$latest_mp4" ]]; then
    cp "$latest_mp4" "$DEST_DIR"
    echo "Copied: $latest_mp4 to $DEST_DIR"
else
    echo "No .mp4 files found in $SRC_DIR"
fi

