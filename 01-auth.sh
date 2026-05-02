#set -euo pipefail

resp="$(
  curl -sS -X POST https://api.openprovider.eu/v1beta/auth/login \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"$OP_USER\", \"password\": \"$OP_PASS\", \"ip\": \"0.0.0.0\"}"
)"
echo "$resp"

if command -v jq >/dev/null 2>&1; then
  OP_TOKEN="$(jq -r '.data.token // empty' <<<"$resp")"
else
  # Minimal fallback if jq isn't installed (assumes token is a simple string).
  OP_TOKEN="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("data",{}).get("token",""))' <<<"$resp")"
fi

if [[ -z "${OP_TOKEN:-}" ]]; then
  echo "Failed to extract token from response:" >&2
  echo "$resp" >&2
  exit 1
fi

export OP_TOKEN
echo "OP_TOKEN=$OP_TOKEN"