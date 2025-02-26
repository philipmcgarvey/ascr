ASCR_DIR="/storage/3133-3532/ascr"

function sm() {
  original_dir=$(pwd)
  cd $ASCR_DIR
  git pull origin main
  source "$ASCR_DIR/main.sh"
  echo "sourced main 2"
  cd "$original_dir"
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
find . -maxdepth 1 -type f -print0 | sort -z | while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
        new_time=$((latest_timestamp + counter))
        formatted_time=$(date -u -r "@$new_time" +%Y%m%d%H%M.%S 2>/dev/null || busybox date -u -d "@$new_time" +%Y%m%d%H%M.%S 2>/dev/null)
        
        if [[ -z "$formatted_time" ]]; then
            echo "Error: Could not format timestamp."
            exit 1
        fi
        
        touch -t "$formatted_time" "$file"
        ((counter++))
    fi
done}
