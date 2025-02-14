cd /storage/3133-3532/ascr
bash fetch-latest-audio.sh

name=$(cat audio_name.txt)
echo "$name"

bash pa.sh -a "$name"
