#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
renew_script="$SCRIPT_DIR/04-renew.sh"

if [[ ! -x "$renew_script" ]]; then
  # Still allow running if not executable; we'll invoke via bash.
  true
fi

print_usage() {
  echo "Usage:" >&2
  echo "  $0 domain1.tld domain2.tld ..." >&2
  echo "  $0            # then paste domains (one per line), end with Ctrl+D" >&2
  echo "  DEBUG=1 $0 ...  # print extra debug output" >&2
  echo "" >&2
  echo "Notes:" >&2
  echo "  - Empty lines and lines starting with # are ignored." >&2
  echo "  - Ctrl+C stops the whole batch immediately." >&2
}

stop_now=0
on_int() {
  stop_now=1
  echo "" >&2
  echo "Interrupted (Ctrl+C). Stopping bulk renew." >&2
}
trap on_int INT

domains=()

if [[ $# -gt 0 ]]; then
  domains=("$@")
else
  # Paste-mode: read domains from stdin
  if [[ -t 0 ]]; then
    echo "Paste domains (one per line). Finish with Ctrl+D." >&2
  fi
  while IFS= read -r line; do
    # strip leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue
    domains+=("$line")
  done
fi

if [[ ${#domains[@]} -eq 0 ]]; then
  print_usage
  exit 2
fi

total=${#domains[@]}
ok=0
fail=0

for i in "${!domains[@]}"; do
  (( stop_now )) && exit 130

  domain="${domains[$i]}"
  n=$((i + 1))
  echo "[$n/$total] Renew: $domain"

  out="$(bash "$renew_script" "$domain" 2>&1)"
  status=$?

  if [[ "${DEBUG:-0}" == "1" ]]; then
    echo "[$n/$total] DEBUG: exit=$status output follows"
    printf '%s\n' "$out"
    echo "[$n/$total] DEBUG: end output"
  fi

  if [[ $status -ne 0 ]]; then
    echo "[$n/$total] ERROR (exit=$status): $domain" >&2
    [[ -n "$out" ]] && printf '%s\n' "$out" >&2
    ((fail++))
    continue
  fi

  [[ -n "$out" ]] && printf '%s\n' "$out"
  ((ok++))
done

echo "Done. ok=$ok failed=$fail total=$total"
if [[ $fail -ne 0 ]]; then
  exit 1
fi
exit 0
