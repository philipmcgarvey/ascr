#!/bin/bash

# Define source and destination directories
SRC_DIR="../Recordings"
DEST_DIR="./audio"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Find the most recently modified .wav file and copy it
latest_wav=$(ls -t "$SRC_DIR"/*.wav 2>/dev/null | head -n 1)

if [[ -n "$latest_wav" ]]; then
    cp "$latest_wav" "$DEST_DIR"
    echo "Copied: $latest_wav to $DEST_DIR"
else
    echo "No .wav files found in $SRC_DIR"
fi
