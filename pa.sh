function get_latest_file() {
  folder=$1  # First argument is the directory path

  # Check if directory exists
  if [ ! -d "$folder" ]; then
    echo "Directory does not exist: $folder"
    return 1  # Return error status
  fi

  # Get the most recently modified file using ls
  latest_file=$(ls -t "$folder" | head -n 1)

  # Check if directory is empty
  if [ -z "$latest_file" ]; then
    echo "No files found in $folder"
    return 1
  fi

  # Return the full file path
  echo "$folder/$latest_file"
}



function move_random_image() {
  unused_dir="unused_images"
  used_dir="used_images"

  # Check if there are any images in the unused_images directory
  
  # If there are images in the unused_images dir
  if ls $unused_images/*.jpg &> /dev/null; then
    # No images in unused_images, so move all from used_images to unused_images
    mv used_images/* unused_images/
  fi

  
  if ls $unused_images/*.jpg &> /dev/null; then
    echo "Sorry no images found."
  else
    # Pick a random image from unused_images
    random_image=$(get_latest_file $unused_dir)
    
    # Move the image to used_images
    mv "$random_image" "$used_dir"
    
    # Return the new path of the moved image
    echo "$used_dir/$(basename "$random_image")"
  fi
}


function sanitize_string() {
    local input="$1"
    local sanitized="${input//\'/}"  # Remove apostrophes
    sanitized="${sanitized//\//-}"   # Replace slashes with dashes
    echo "$sanitized"
}

function process_audio() {

  original_name="$1"
  crop_start="$2"
  crop_end="$3"
  name=$(sanitize_string "$original_name")
#  name=$original_name
  date=$(date +"%Y%m%d_%H%M%S")
  month=$(date +"%Y%m")
  mname="${month}_${name}"
  processed_dir="processed"
  audio_dir="audio"
  unused_images_dir="unused_images"
  used_images_dir="used_images"
  
  # Create the directory inside processed with name "$date $name"
  new_dir="$processed_dir/$date $name"
  mkdir -p "$new_dir"
  
  # Find the most recently modified .wav file in the audio directory
  latest_file=$(ls -t "$audio_dir"/*.mp3 "$audio_dir"/*.wav 2>/dev/null | head -n 1)

  s=""
  # Add cropping if specified
  if [[ -n "$crop_start" && -n "$crop_end" ]]; then
      crop=" -ss $crop_start -to $crop_end"
  fi
  
  # If a .wav file was found, copy it to the new directory and rename it
  if [ -n "$latest_file" ]; then
    # Apply low-pass filter at 3000Hz and high-pass filter at 80Hz
    ffmpeg -i "$latest_file" -af "highpass=f=80, lowpass=f=3000, loudnorm" $crop "$new_dir/$mname.wav"
    #cp "$latest_wav" "$new_dir/$date $name.wav"
    #echo "Applied filters and saved: $new_dir/$mname.wav"
    
    # Create an mp3 version of the filtered wav file
    ffmpeg -i "$new_dir/$mname.wav" "$new_dir/$mname.mp3"
   # echo "Processed: $new_dir/$month_$name.wav and $new_dir/$month_$name.mp3"
  else
    echo "No .wav or .mp3 files found in $audio_dir"
  fi 

  # Call move_random_image to get the image path
  moved_image=$(move_random_image)
  echo "$moved_image"
  
  # Check if move_random_image returned a valid image path
  if [ -n "$moved_image" ]; then
    # Copy the image to the new directory
    cp "$moved_image" "$new_dir/"
    #echo "Copied image: $moved_image to $new_dir"
  else
    echo "No image found to copy"
  fi

  ffmpeg -loop 1 -i "$moved_image" -i "$new_dir/$mname.wav" -c:v mpeg4 -tune stillimage -preset fast -crf 18 -c:a aac -b:a 192k -pix_fmt yuv420p -movflags +faststart -shortest "$new_dir/$mname.mp4"
  echo "$new_dir/$mname.mp4"
}

function process_video() {

  original_name="$1"
  name=$(sanitize_string "$original_name")
#  name=$original_name
  date=$(date +"%Y%m%d_%H%M%S")
  month=$(date +"%Y%m")
  mname="${month}_${name}"
  processed_dir="processed"
  video_dir="video"
  
  # Create the directory inside processed with name "$date $name"
  new_dir="$processed_dir/$date $name"
  mkdir -p "$new_dir"
  
  # Find the most recently modified .wav file in the audio directory
  latest_vid=$(ls -t "$video_dir"/*.mp4 | head -n 1)
  
  # If a .wav file was found, copy it to the new directory and rename it
  if [ -n "$latest_vid" ]; then
    # Apply low-pass filter at 3000Hz and high-pass filter at 80Hz
    ffmpeg -i "$latest_vid" -af "highpass=f=80, lowpass=f=3000" -c:v copy -c:a aac "$new_dir/$mname.mp4"
    
    # Create an mp3 version of the filtered wav file
    ffmpeg -i "$new_dir/$mname.mp4" -q:a 2 -vn "$new_dir/$mname.mp3"
    echo "$new_dir/$mname.mp4"
  else
    echo "No .mp4 files found in $audio_dir"
  fi 
}
#!/bin/bash





# Default values
CROP_START=""
CROP_END=""
CROP=""
MODE=""
NAME="output"

# Function to display usage
usage() {
    echo "Usage: $0 (-a | -v) [-c start,end] [-n name]"
    exit 1
}

# Parse command-line arguments
while getopts ":avc:n:" opt; do
    case $opt in
        a) MODE="audio" ;;
        v) MODE="video" ;;
        c) CROP=$OPTARG
            if [[ $OPTARG =~ ^[0-9]+\,[0-9]+$ ]]; then
                CROP_START=$(echo "$OPTARG" | cut -d',' -f1)
                CROP_END=$(echo "$OPTARG" | cut -d',' -f2)
            else
                echo "Invalid crop format. Use start|end (e.g., 5,10)."
                usage
            fi
            ;;
        n) NAME="$OPTARG" ;;
        *) usage ;;
    esac
done

# Ensure -a or -v is provided
if [[ -z "$MODE" ]]; then
    echo "Error: You must specify either -a (audio) or -v (video)."
    usage
fi

if [ -z "$NAME" ]; then
  NAME=$(cat audio_name.txt)
  echo "No name provided, using '$NAME'"
else
  echo "Name is '$NAME'"
fi

video_file="empty"

# Process the flag
case "$MODE" in
    "video") video_file=$(process_video "$name") ;;
    "audio") video_file=$(process_audio "$name" "$CROP_START" "$CROP_END") ;;
    *) echo "Error: Invalid option. Use '-v' for video or '-a' for audio." >&2; exit 1 ;;
esac

echo "$video_file"

exit


month=$(date +"%Y%m")

am start -a android.intent.action.SEND \
  -t video/* \
  -e android.intent.extra.STREAM "file://$(pwd)/$video_file" \
  -e android.intent.extra.SUBJECT "$2" \
  -e android.intent.extra.TEXT "$month" \
  --activity-package com.google.android.youtube
#  -n com.google.android.youtube/.UploadActivity
