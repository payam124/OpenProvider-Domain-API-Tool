#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

domain="${1:-}"
if [[ -z "$domain" ]]; then
  echo "Usage: $0 <domain>" >&2
  echo "Example: $0 greatdomain1.info" >&2
  exit 2
fi

err_file="$(mktemp)"
trap 'rm -f "$err_file"' EXIT

domain_id="$(bash "$SCRIPT_DIR/03-get-domainid.sh" "$domain" 2>"$err_file")"
status=$?

if [[ $status -ne 0 ]]; then
  # Bubble up the underlying error message from 03-get-domainid.sh
  cat "$err_file" >&2
  exit $status
fi

if [[ "${domain_id:-}" == "0" || "${domain_id:-}" == "-1" ]]; then
  echo "Domain was not found: $domain" >&2
  exit 3
fi

echo "Renewing $domain (id=$domain_id)"
curl -sS -X POST "https://api.openprovider.eu/v1beta/domains/$domain_id/renew" \
  -H "Authorization: Bearer $OP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"period": 1}'