#!/bin/bash

for file in ../Recordings/*.wav; do
  if [[ -f "$file" ]]; then
    output="${file%.wav}.m4a"
    ffmpeg -i "$file" -c:a aac -b:a 192k "$output" && rm "$file"
    echo "converted and deleted $file"
  fi
done
