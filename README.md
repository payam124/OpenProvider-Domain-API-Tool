# OpenProvider Domain API tools

Small **bash** utilities for [OpenProvider](https://www.openprovider.com/) domain operations via their REST API (`api.openprovider.eu`). They cover the flows that are awkward or slow in the reseller control panel.

## Why this repo exists

The OpenProvider web panel is not as smooth or efficient as **HexoNet’s** for day‑to‑day work. Even simple tasks often mean more clicks and more time in the browser. This repo is a **gradual collection** of scripts I add whenever I need to speed up something recurring—listing domains, resolving IDs, renewals, and bulk renew—without living in the UI.

## Requirements

- **bash**, **curl**
- **jq** (required for listing domains and resolving domain IDs; login can fall back to **Python 3** for token parsing if `jq` is missing)

## Setup

1. Clone or copy this directory.
2. Edit `00-env.sh` and set your API credentials:

   - `OP_USER` — OpenProvider username  
   - `OP_PASS` — OpenProvider password  

   Treat this like a password file: **do not commit real credentials**. Prefer a private copy, `chmod 600`, or inject the variables from your shell / a secrets manager instead of keeping secrets in the tracked file.

3. Authenticate and export a bearer token (needed for all other calls):

   ```bash
   set -a
   source ./00-env.sh
   source ./01-auth.sh
   set +a
   ```

   `01-auth.sh` prints the raw login response, then sets `OP_TOKEN`. If login fails, it exits non‑zero.

## Scripts (run from repo root after auth)

| File | Purpose |
|------|--------|
| `00-env.sh` | Defines `OP_USER` / `OP_PASS` (template—fill in locally). |
| `01-auth.sh` | `POST …/auth/login` → exports `OP_TOKEN`. |
| `02-get-domains.sh` | Lists **active** domains as TSV: `id`, `expiration_date`, `autorenew`, `fqdn` (sorted by expiration, soonest first). |
| `03-get-domainid.sh` | `03-get-domainid.sh example.com` — prints the numeric domain id, or `0` if not found. |
| `04-renew.sh` | `04-renew.sh example.com` — renews one domain for **1 year** (`period: 1`). |
| `05-renew-bulk.sh` | Renews many domains: pass FQDNs as args, or run with no args and paste one domain per line (finish with Ctrl+D). Empty lines and `#` comments are ignored. Set `DEBUG=1` for extra output. Summary line: `ok=… failed=… total=…`. |

### Examples

```bash
# After sourcing env + auth as above
./02-get-domains.sh

./03-get-domainid.sh mybrand.io

./04-renew.sh mybrand.io

./05-renew-bulk.sh a.com b.net c.org

# Or paste list from clipboard
./05-renew-bulk.sh
```

## API notes

- Base URL used: `https://api.openprovider.eu/v1beta/`.
- Domain listing filters to **status `ACT`** (active), matching the scripts’ queries.
- Renewals use a fixed **1‑year** period in `04-renew.sh` / `05-renew-bulk.sh`; adjust the JSON body in `04-renew.sh` if you need a different period.

## License

See [LICENSE](LICENSE) (MIT).
