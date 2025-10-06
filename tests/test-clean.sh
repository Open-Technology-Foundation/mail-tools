#!/bin/bash
# Test script to process emails with bloat headers removed
set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

declare -r SCRIPT_PATH=$(readlink -en -- "$0")
declare -r SCRIPT_DIR=${SCRIPT_PATH%/*}
declare -r SCRIPT_NAME=${SCRIPT_PATH##*/}

declare -i VERBOSE=1 DRYRUN=1

xcleanup() { local -i exitcode=${1:-"$?"}; exit $exitcode; }
trap 'xcleanup $?' SIGINT SIGTERM EXIT

vecho() { ((VERBOSE)) || return 0; >&2 printf '%s\n' "$*"; }
info() { ((VERBOSE)) || return 0; >&2 printf '%s: info: %s\n' "$SCRIPT_NAME" "$*"; }
warn() { >&2 printf '%s: warning: %s\n' "$SCRIPT_NAME" "$*"; }
error() { >&2 printf '%s: error: %s\n' "$SCRIPT_NAME" "$*"; }
die() { (($# > 1)) && error "${@:2}"; exit "${1:-0}"; }

enable -f /usr/local/lib/bash/loadables/mailheaderclean.so mailheaderclean || \
    die 3 'enable builtin mailheaderclean failed'
info "$(type mailheaderclean)"

declare -- SOURCE_MDIR=/tmp/"$SCRIPT_NAME"/source
SOURCE_MDIR=$(readlink -fn -- "$SOURCE_MDIR")
mkdir -p "$SOURCE_MDIR"
# copy test data
rsync -a "$SCRIPT_DIR"/test-data/ "$SOURCE_MDIR"/

declare -- DEST_MDIR=/tmp/"$SCRIPT_NAME"/cleaned
DEST_MDIR=$(readlink -fn -- "$DEST_MDIR")
mkdir -p "$DEST_MDIR"
rm -f "$DEST_MDIR"/*

declare -- efile destfile
declare -i original_size cleaned_size saved total_saved=0

declare -a eFiles
readarray -t eFiles < <(find "$SOURCE_MDIR" -maxdepth 1 -type f)

declare -a error_files=()

for efile in "${eFiles[@]}"; do
  original_size=$(stat -c%s "$efile")
  destfile="$DEST_MDIR/$(basename "$efile")"
  mailheaderclean "$efile" > "$destfile" || {
    error "mailheaderclean error $? for '$efile'"
    error_files+=("$efile")
    continue
  }
  # Preserve timestamps
  touch -r "$efile" "$destfile" || {
    error "touch error $? for '$efile'"
    error_files+=("$efile")
    continue
  }

  cleaned_size=$(stat -c%s "$destfile")
  saved=$((original_size - cleaned_size))
  info "Saved $saved bytes on $(basename "$efile")"
  total_saved+=$saved

  ((DRYRUN)) || mv "$destfile" "$efile"

done

if ((${#error_files[@]})); then
  vecho "Errors occurred for these files:"
  for efile in "${error_files[@]}"; do
    vecho "    $efile"
  done
fi
vecho "Total $total_saved bytes saved in $SOURCE_MDIR"

#fin
