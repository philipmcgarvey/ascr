ASCR_DIR="/storage/3133-3532/ascr"

function sm() {
  source "$ASCR_DIR/main.sh"
  echo "sourced main"
}

function sort-modify() {
  bash "$ASCR_DIR/sort-modify-dates.sh"
}
