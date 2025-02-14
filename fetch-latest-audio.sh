#!/bin/bash


strip_to_first_letter() {
  # Check if an argument is provided
  if [ -z "$1" ]; then
    echo "Usage: strip_to_first_letter <filename>"
    return 1
  fi

  # Extract the basename (remove directory path)
  basename_only=$(basename "$1")

  # Remove the extension
  name_no_ext="${basename_only%.*}"

  # Use sed to strip leading non-letter characters
  stripped_name=$(echo "$name_no_ext" | sed -E 's/^[^a-zA-Z]+//')

  echo "$stripped_name"
}

# Define source and destination directories
SRC_DIR="../Recordings"
DEST_DIR="./audio"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Find the most recently modified .wav file and copy it
latest_wav=$(ls -t "$SRC_DIR"/*.wav 2>/dev/null | head -n 1)
echo "copying: $latest_wav to $DEST_DIR"
name="$(strip_to_first_letter "$latest_wav")"
echo "$name" > audio_name.txt

if [[ -n "$latest_wav" ]]; then
    cp "$latest_wav" "$DEST_DIR"
    echo "Copied: $latest_wav to $DEST_DIR"
else
    echo "No .wav files found in $SRC_DIR"
fi
