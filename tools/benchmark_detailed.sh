#!/bin/bash
# Detailed benchmark showing scaling with different email counts

set -euo pipefail

EMAIL_DIR="${1:-./test_emails}"

if [[ ! -d "$EMAIL_DIR" ]]; then
  echo "Error: $EMAIL_DIR does not exist"
  echo "Usage: $0 [EMAIL_DIR]"
  echo ""
  echo "Please provide a directory containing email files, or create ./test_emails/"
  exit 1
fi

# Get all email files
mapfile -t ALL_FILES < <(find "$EMAIL_DIR" -type f)
declare -i TOTAL_FILES=${#ALL_FILES[@]}

if ((TOTAL_FILES == 0)); then
  echo "Error: No email files found in $EMAIL_DIR"
  exit 1
fi

echo "Mailheader Detailed Performance Comparison"
echo "==========================================="
echo "Email directory: $EMAIL_DIR"
echo "Total emails available: $TOTAL_FILES"
echo ""

printf "%-10s | %-15s | %-15s | %-10s | %-15s\n" "Emails" "Standalone" "Builtin" "Speedup" "Time Saved"
printf "%-10s-+-%-15s-+-%-15s-+-%-10s-+-%-15s\n" "----------" "---------------" "---------------" "----------" "---------------"

for count in 10 25 50 100 200 500; do
  ((count > TOTAL_FILES)) && break

  # Get subset of files
  EMAIL_FILES=("${ALL_FILES[@]:0:$count}")

  # Benchmark standalone
  declare -i start end standalone_ms
  start=$(date +%s%N)
  for file in "${EMAIL_FILES[@]}"; do
    /usr/local/bin/mailheader "$file" > /dev/null 2>&1
  done
  end=$(date +%s%N)
  ((standalone_ms = (end - start) / 1000000))

  # Benchmark builtin
  declare tmpfile
  tmpfile=$(mktemp)
  printf "%s\n" "${EMAIL_FILES[@]}" > "$tmpfile"

  start=$(date +%s%N)
  bash -c '
    enable -f mailheader.so mailheader 2>/dev/null
    while IFS= read -r file; do
      mailheader "$file" > /dev/null 2>&1
    done < "$1"
  ' _ "$tmpfile"
  end=$(date +%s%N)
  declare -i builtin_ms
  ((builtin_ms = (end - start) / 1000000))

  rm -f "$tmpfile"

  # Calculate speedup
  declare speedup_fmt
  if ((builtin_ms > 0)); then
    declare -i speedup
    ((speedup = standalone_ms * 10 / builtin_ms))
    speedup_fmt="${speedup:0:-1}.${speedup: -1}x"
  else
    speedup_fmt="N/A"
  fi

  declare -i saved
  ((saved = standalone_ms - builtin_ms))

  printf "%-10d | %-13s ms | %-13s ms | %-10s | %-13s ms\n" \
    "$count" "$standalone_ms" "$builtin_ms" "$speedup_fmt" "$saved"
done

echo ""
echo "Summary:"
echo "  - The builtin eliminates fork/exec overhead"
echo "  - Speedup increases with number of calls"
echo "  - Ideal for scripts processing many emails"

#fin
