#!/bin/bash
set -euo pipefail

getheader() {
  local -n headers="$1"
  [[ -f "$2" ]] || return 1
  headers=()
  local -- line
  while read -r line; do
    #shellcheck disable=SC2034
    headers[${line%%:*}]="${line#*: }"
  done < <(mailheader "$2")
  return 0
}


declare -A Headers
declare -- file=/home/vmail/okusi.dev/gary/.bank/cur/1759639586.M944361P3106720.okusi0:2,a

getheader Headers "$file" || exit $?

declare -p Headers
 
#fin
