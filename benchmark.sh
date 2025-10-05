#!/bin/bash
# Benchmark script to compare mailheader builtin vs standalone

set -euo pipefail

EMAIL_DIR="${1:-./test_emails}"

# Check if directory exists
if [[ ! -d "$EMAIL_DIR" ]]; then
  echo "Error: $EMAIL_DIR does not exist"
  echo "Usage: $0 [EMAIL_DIR]"
  echo ""
  echo "Please provide a directory containing email files, or create ./test_emails/"
  exit 1
fi

# Get list of email files
mapfile -t EMAIL_FILES < <(find "$EMAIL_DIR" -type f | head -100)
declare -i NUM_FILES=${#EMAIL_FILES[@]}

if ((NUM_FILES == 0)); then
  echo "Error: No email files found in $EMAIL_DIR"
  exit 1
fi

echo "Mailheader Performance Comparison"
echo "=================================="
echo "Using emails from: $EMAIL_DIR"
echo "Number of emails: $NUM_FILES"
echo ""

# Benchmark standalone binary
echo "Testing standalone binary..."
echo -n "  Processing... "
declare -i start end standalone_time standalone_ms standalone_avg
start=$(date +%s%N)
for file in "${EMAIL_FILES[@]}"; do
  /usr/local/bin/mailheader "$file" > /dev/null
done
end=$(date +%s%N)
((standalone_time = end - start))
((standalone_ms = standalone_time / 1000000))
((standalone_avg = standalone_time / NUM_FILES / 1000))
echo "done"

echo "  Total time: ${standalone_ms} ms"
echo "  Average per email: ${standalone_avg} μs"
echo ""

# Benchmark builtin (pre-loaded in single bash session)
echo "Testing bash builtin..."
echo -n "  Processing... "

# Create a temporary file with the list
declare tmpfile
tmpfile=$(mktemp)
printf "%s\n" "${EMAIL_FILES[@]}" > "$tmpfile"

start=$(date +%s%N)
bash -c '
  enable -f mailheader.so mailheader 2>/dev/null
  while IFS= read -r file; do
    mailheader "$file" > /dev/null
  done < "$1"
' _ "$tmpfile"
end=$(date +%s%N)

rm -f "$tmpfile"
declare -i builtin_time builtin_ms builtin_avg
((builtin_time = end - start))
((builtin_ms = builtin_time / 1000000))
((builtin_avg = builtin_time / NUM_FILES / 1000))
echo "done"

echo "  Total time: ${builtin_ms} ms"
echo "  Average per email: ${builtin_avg} μs"
echo ""

# Calculate speedup
echo "Results:"
echo "--------"
if ((builtin_ms > 0)); then
  declare -i speedup speedup_int speedup_dec
  ((speedup = standalone_ms * 100 / builtin_ms))
  ((speedup_int = speedup / 100))
  ((speedup_dec = speedup % 100))

  echo "Builtin is ${speedup_int}.${speedup_dec}x faster"

  declare -i time_saved
  ((time_saved = standalone_ms - builtin_ms))
  echo "Time saved: ${time_saved} ms over $NUM_FILES emails"

  if ((NUM_FILES > 0)); then
    declare -i saved_per_call
    ((saved_per_call = time_saved * 1000 / NUM_FILES))
    echo "Savings per call: ${saved_per_call} μs"
  fi
fi

echo ""
echo "Explanation:"
echo "  Standalone: Each call requires fork() + exec() + process startup"
echo "  Builtin:    Runs in-process, no fork/exec overhead"

#fin
