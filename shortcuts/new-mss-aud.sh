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
SRC_DIR="/storage/emulated/0/Music/MusicSpeedChanger"
DEST_DIR="./audio"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Find the most recently modified .mp3 file and copy it
latest_mp3=$(ls -t "$SRC_DIR"/*.mp3 2>/dev/null | head -n 1)
echo "copying: $latest_mp3 to $DEST_DIR"
name="$(strip_to_first_letter "$latest_mp3")"
echo "$name" > audio_name.txt

if [[ -n "$latest_mp3" ]]; then
    cp "$latest_mp3" "$DEST_DIR"
    echo "Copied: $latest_mp3 to $DEST_DIR"
else
    echo "No .mp3 files found in $SRC_DIR"
fi
