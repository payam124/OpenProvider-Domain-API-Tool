#set -euo pipefail

resp="$(
  curl -sS -X GET \
    -H "Authorization: Bearer $OP_TOKEN" \
    'https://api.openprovider.eu/v1beta/domains?status=ACT'
)"

# Output: domain autorenew expiration_date id (sorted by expiration_date asc)
if command -v jq >/dev/null 2>&1; then
  jq -r '
    (.data.results // [])
    | sort_by(.expiration_date // "")
    | .[]
    | [
        (.id // ""),
        (.expiration_date // ""),
        (.autorenew // ""),
        ((.domain.name // "") + "." + (.domain.extension // ""))
      ]
    | @tsv
  ' <<<"$resp"
else
  echo "jq is required for domain extraction/sorting. Install jq and re-run." >&2
  exit 2
fi