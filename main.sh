export ASCR_STORAGE="/storage/3364-3533"
export ASCR_DIR="$ASCR_STORAGE/ascr"

function sm() {
  original_dir=$(pwd)
  cd $ASCR_DIR
  git pull origin main
  source "$ASCR_DIR/main.sh"
  echo "sourced main 2"
  cd "$original_dir"
}

function ascr-dir() {
  echo "$ASCR_DIR"
}
export -f ascr-dir

function new-aud() {
  bash fetch-latest-audio.sh
}
function new-vid() {
  bash fetch-latest-video.sh
}

# usage yt-single https://www.youtube.com/watch?v=sJWdjtNOM08
function yt-single() {
  yt-dlp -f bestaudio[ext=m4a] --embed-thumbnail --add-metadata --output "%(title)s.%(ext)s" --metadata-from-title "%(title)s" "$1"
}

# usage yt-pl "https://www.youtube.com/watch?v=UX3Fq7QZmaw&list=OLAK5uy_kqwySEJBXUgxIFopOHwUFOm-YMIl3TEvg&index=2" "Oisin - On the fiddle"
function yt-pl() {
yt-dlp -f bestaudio --extract-audio --audio-format m4a --write-thumbnail --add-metadata \
  --output "$2/%(title)s.%(ext)s" --metadata-from-title "%(title)s" "$1"
}


function sort-modify() {
  # updates all files last modified dates in current directory so that a last-modified sort gives same results as alphabetical sort

# Get the most recent modification time in the directory (in seconds since epoch)
latest_file=$(ls -t | head -n 1)
latest_timestamp=$(stat -c "%Y" "$latest_file")
echo "fil: $latest_file tim: $latest_timestamp"

# Ensure we have a valid timestamp
if [[ -z "$latest_timestamp" ]]; then
    echo "Error: Could not determine the latest file modification time."
    exit 1
fi

# Sort files alphabetically and update timestamps
counter=0
find . -maxdepth 1 -type f ! -name ".*" -print0 | sort -z | while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
        new_time=$((latest_timestamp + counter))
        formatted_time=$(date -u -d "@$new_time" +%Y%m%d%H%M.%S 2>/dev/null || busybox date -u -d "@$new_time" +%Y%m%d%H%M.%S 2>/dev/null)
        
        if [[ -z "$formatted_time" ]]; then
            echo "Error: Could not format timestamp."
            exit 1
        fi
        
        touch -t "$formatted_time" "$file"
        ((counter++))
    fi
done
}

function amdtpd() {
#!/bin/bash

# Iterate through all audio files in the current directory
for file in *.mp3 *.wav *.flac *.m4a; do
  # Check if file exists (in case there are no audio files)
  if [[ -f "$file" ]]; then
    # Get the file's last modified date
    mod_date=$(stat -c %y "$file" | cut -d' ' -f1)
    
    # Use ffmpeg to set the publication date metadata
    # Wrap filenames in double quotes to handle spaces and special characters
    ffmpeg -i "$file" -metadata date="$mod_date" -codec copy "${file%.*}_updated.${file##*.}"
    
    echo "Updated publication date for '$file' to $mod_date"
  fi
done
}

function rename_bunch_of_files(){
#!/bin/bash

# Remove all files that don't have "_updated" in the name
for file in *; do
  if [[ -f "$file" && ! "$file" =~ _updated ]]; then
    rm "$file"
    echo "Removed $file"
  fi
done

# Rename files by removing "_updated" from the names of the remaining files
for file in *_updated*; do
  if [[ -f "$file" ]]; then
    new_name="${file/_updated/}"
    mv "$file" "$new_name"
    echo "Renamed $file to $new_name"
  fi
done
}


function yta() {
  # Check if yt-dlp is installed
  if ! command -v yt-dlp &> /dev/null; then
      echo "yt-dlp is not installed. Please install it first."
      exit 1
  fi

  # Check if a URL is provided
  if [ -z "$1" ]; then
      echo "Usage: $0 <YouTube-URL>"
      exit 1
  fi

  URL="$1"

  # Get video title and sanitize it for use as a folder name
  VIDEO_TITLE=$(yt-dlp --get-title "$URL" | sed -E 's/[^a-zA-Z0-9_ -]+/_/g; s/^_+|_+$//g')
  mkdir -p "$VIDEO_TITLE"

  # Download audio as m4a
  yt-dlp -f bestaudio[ext=m4a] -o "$VIDEO_TITLE/%(title)s.%(ext)s" "$URL"

  # Download description
  yt-dlp --write-description --skip-download -o "$VIDEO_TITLE/%(title)s.txt" "$URL"

  # Download thumbnail as low-quality jpg
  yt-dlp --write-thumbnail --convert-thumbnails jpg --skip-download -o "$VIDEO_TITLE/%(title)s" "$URL"

  echo "Download completed and saved in '$VIDEO_TITLE' folder."
}




function extract_tracks() {

# Find the first .m4a file in the current directory
AUDIO_FILE=$(ls *.m4a 2>/dev/null | head -n 1)
TEXT_FILE=$(ls *.txt 2>/dev/null | head -n 1)

# Check if both files exist
if [[ -z "$AUDIO_FILE" || -z "$TEXT_FILE" ]]; then
    echo "Error: Missing .m4a or .txt file in the current directory."
    exit 1
fi

echo "Using audio file: $AUDIO_FILE"
echo "Using timestamp file: $TEXT_FILE"

# Convert timestamp (m:ss) to seconds
timestamp_to_seconds() {
    local ts=$1
    if [[ ! "$ts" =~ ^[0-9]+:[0-9]{2}$ ]]; then
        echo "Error: Invalid timestamp format '$ts'. Expected m:ss."
        exit 1
    fi
    local min=${ts%:*}  # Extract minutes
    local sec=${ts#*:}  # Extract seconds

    # Remove leading zeros to avoid octal interpretation
    min=$((10#$min))
    sec=$((10#$sec))

    echo "$((min * 60 + sec))"
}

# Sanitize filename (replace slashes with ∕, remove other illegal characters, keep quotes)
sanitize_filename() {
    echo "$1" | sed 's/[\/\\]/∕/g; s/[:*?<>|]/_/g'  # Replace slashes with ∕ and remove other illegal characters
}

# Read timestamps and titles from the text file
timestamps=()
titles=()

# Read lines from the text file
while IFS= read -r line || [[ -n "$line" ]]; do  # Ensure the last line is read even if there is no newline at the end
    if [[ "$line" =~ ^([0-9]+:[0-9]{2})\ (.*) ]]; then
        timestamps+=("${BASH_REMATCH[1]}")
        titles+=("${BASH_REMATCH[2]}")
    fi
done < "$TEXT_FILE"

# Check if we found timestamps
if [[ ${#timestamps[@]} -eq 0 ]]; then
    echo "Error: No valid timestamps found in $TEXT_FILE."
    exit 1
fi

# Get total duration of the audio file
RAW_TOTAL_DURATION=$(ffprobe -i "$AUDIO_FILE" -show_entries format=duration -v quiet -of csv="p=0")
TOTAL_DURATION_SEC=${RAW_TOTAL_DURATION%.*}  # Remove decimal part

# Convert total duration from seconds to m:ss format
TOTAL_MIN=$((TOTAL_DURATION_SEC / 60))
TOTAL_SEC=$((TOTAL_DURATION_SEC % 60))
TOTAL_DURATION=$(printf "%d:%02d" $TOTAL_MIN $TOTAL_SEC)


# Process timestamps and extract segments
for i in "${!timestamps[@]}"; do
    START_TIME=${timestamps[$i]}
    echo $START_TIME
    
    # Explicitly handle the last timestamp
    if [[ $((i+1)) -lt ${#timestamps[@]} ]]; then
        END_TIME=${timestamps[$((i+1))]}
    else
        END_TIME="$TOTAL_DURATION"
    fi

    # Convert timestamps to seconds
    START_SEC=$(timestamp_to_seconds "$START_TIME")
    END_SEC=$(timestamp_to_seconds "$END_TIME")
    DURATION=$((END_SEC - START_SEC))

    # Sanitize title for valid filename but keep quotes
    TITLE="${titles[$i]}"
    SAFE_TITLE=$(sanitize_filename "$TITLE")
    OUTPUT_FILE="${SAFE_TITLE}.m4a"

    echo "Extracting from $START_TIME ($START_SEC sec) to $END_TIME ($END_SEC sec) -> $OUTPUT_FILE"

    ffmpeg -i "$AUDIO_FILE" -ss "$START_SEC" -t "$DURATION" -c copy "$OUTPUT_FILE" -y
done

echo "Extraction complete!"
}

function rename_dirs() {
#!/bin/bash

# Loop through each directory in the current directory
for dir in */; do
    # Skip if not a directory
    if [[ ! -d "$dir" ]]; then
        continue
    fi

    # Find the first .m4a file in the directory
    AUDIO_FILE=$(find "$dir" -maxdepth 1 -name "*.m4a" | head -n 1)

    # If a .m4a file is found
    if [[ -n "$AUDIO_FILE" ]]; then
        # Get the filename without the extension
        NEW_DIR_NAME=$(basename "$AUDIO_FILE" .m4a)

        # Rename the directory safely
        mv -- "$dir" "$(dirname "$dir")/$NEW_DIR_NAME"
        
        echo "Renamed directory '$dir' to '$(dirname "$dir")/$NEW_DIR_NAME'"
    fi
done
}

function extract_all_m4as() {

# Loop through each directory in the current directory
for dir in */; do
    # Skip if not a directory
    if [[ ! -d "$dir" ]]; then
        continue
    fi

    # Change to the directory
    cd "$dir" || continue
    
    # Step 1: Rename the first ".description" file by removing the ".description" extension
    DESCRIPTION_FILE=$(find . -maxdepth 1 -name "*.description" | head -n 1)
    if [[ -n "$DESCRIPTION_FILE" ]]; then
        DESCRIPTION_NAME=$(basename "$DESCRIPTION_FILE" .description)
        mv -- "$DESCRIPTION_FILE" "$DESCRIPTION_NAME"
        echo "Renamed '$DESCRIPTION_FILE' to '$DESCRIPTION_NAME'"
    fi

    # Step 2: Check if the .txt file exists and has a line starting with a timestamp (m:ss format)
    TXT_FILE=$(find . -maxdepth 1 -name "*.txt" | head -n 1)
    if [[ -n "$TXT_FILE" ]]; then
        TIMESTAMP_FOUND=$(grep -E '^[0-9]+:[0-9]{2}' "$TXT_FILE" | head -n 1)
        
        if [[ -n "$TIMESTAMP_FOUND" ]]; then
            echo $dir
            # There is at least one line with a timestamp in m:ss format, so call extract_tracks
            if command -v extract_tracks &> /dev/null; then
                echo "Running 'extract_tracks' in '$dir'..."
                #extract_tracks
            else
                echo "Error: 'extract_tracks' command not found."
            fi
        else
            echo "No timestamps found in '$TXT_FILE'. Skipping 'extract_tracks'."
        fi
    else
        echo "No .txt file found in '$dir'. Skipping 'extract_tracks'."
    fi

    # Step 3: Delete the m4a file with the same name as the directory (plus the .m4a extension)
    M4A_FILE="${dir%/}.m4a"


    # Go back to the parent directory
    cd ..
done
}
