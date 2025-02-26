ASCR_DIR="/storage/3133-3532/ascr"

function sm() {
  original_dir=$(pwd)
  cd $ASCR_DIR
  git pull origin main
  source "$ASCR_DIR/main.sh"
  echo "sourced main"
  cd "$original_dir"
}

function sort-modify() {
  # updates all files last modified dates in current directory so that a last-modified sort gives same results as alphabetical sort

# Get the most recent modification time in the directory (in seconds since epoch)
latest_file=$(ls -t | head -n 1)
latest_timestamp=$(stat -c "%Y" "$latest_file")

# Sort files alphabetically and update timestamps
counter=0
for file in $(ls -1 | sort); do
    if [[ -f "$file" ]]; then
        new_time=$((latest_timestamp + counter))
        echo "$new_time"
        touch -t "$(date -u -r "$new_time" +%Y%m%d%H%M.%S)" "$file"
        ((counter++))
    fi
done

}
