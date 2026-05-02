#!/usr/bin/env bash
set -euo pipefail

domain="${1:-}"
if [[ -z "$domain" ]]; then
  echo "Usage: $0 <domain>" >&2
  echo "Example: $0 greatdomain1.info" >&2
  exit 2
fi

if [[ "$domain" != *.* ]]; then
  echo "Error: domain must contain at least one dot (e.g. example.com)" >&2
  exit 2
fi

# Use only the first label (strip everything after first dot).
# Example: domain.com.br -> domain
domain_name_pattern="${domain%%.*}"

resp="$(
  curl -sS -G 'https://api.openprovider.eu/v1beta/domains' \
    -H "Authorization: Bearer $OP_TOKEN" \
    --data-urlencode "status=ACT" \
    --data-urlencode "limit=40" \
    --data-urlencode "domain_name_pattern=$domain_name_pattern"
)"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for domain id extraction. Install jq and re-run." >&2
  exit 2
fi

domain_id="$(
  jq -r --arg fqdn "$domain" '
    (.data.results // [])
    | map(select((.domain.name // "") + "." + (.domain.extension // "") == $fqdn))
    | .[0].id // empty
  ' <<<"$resp"
)"

if [[ -n "${domain_id:-}" ]]; then
  echo "$domain_id"
  exit 0
fi

# Not found: print 0 (useful for scripting).
echo 0
exit 0