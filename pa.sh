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
  latest_wav=$(ls -t "$audio_dir"/*.wav | head -n 1)
  
  # If a .wav file was found, copy it to the new directory and rename it
  if [ -n "$latest_wav" ]; then
    # Apply low-pass filter at 3000Hz and high-pass filter at 80Hz
    ffmpeg -i "$latest_wav" -af "highpass=f=80, lowpass=f=3000" "$new_dir/$mname.wav"
    #cp "$latest_wav" "$new_dir/$date $name.wav"
    #echo "Applied filters and saved: $new_dir/$mname.wav"
    
    # Create an mp3 version of the filtered wav file
    ffmpeg -i "$new_dir/$mname.wav" "$new_dir/$mname.mp3"
   # echo "Processed: $new_dir/$month_$name.wav and $new_dir/$month_$name.mp3"
  else
    echo "No .wav files found in $audio_dir"
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

# Ensure at least two arguments are provided
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <name> -a|-v"
    exit 1
fi

# Assign first argument to name
filetype="$1"
video_file="empty"

# Process the flag
case "$filetype" in
    "-v") video_file=$(process_video "$2") ;;
    "-a") video_file=$(process_audio "$2") ;;
    *) echo "Error: Invalid option. Use '-v' for video or '-a' for audio." >&2; exit 1 ;;
esac

echo "$video_file"

#exit


month=$(date +"%Y%m")

am start -a android.intent.action.SEND \
  -t video/* \
  -e android.intent.extra.STREAM "file://$(pwd)/$video_file" \
  -e android.intent.extra.SUBJECT "$2" \
  -e android.intent.extra.TEXT "$month" \
  -n com.google.android.youtube/.UploadActivity
