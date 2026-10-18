#!/usr/bin/env bash
# pmkit: check which local model servers are running. Probes only. Installs nothing.
# Checked: 2026-10-17. See guides/local-models.md.
set -euo pipefail

DRY_RUN=0
OLLAMA_URL="http://localhost:11434/api/tags"
LMSTUDIO_URL="http://localhost:1234/v1/models"

usage() {
  cat <<'EOF'
Usage: bash check-local-model.sh [--dry-run] [--yes] [--help]

Probes two local addresses and lists the models they report:
  Ollama     http://localhost:11434/api/tags
  LM Studio  http://localhost:1234/v1/models
It installs nothing and writes nothing. Both requests stay on localhost.

  --dry-run   Print what would be probed. Make no requests.
  --yes       Accepted for consistency with the other installers. No effect.
  --help      Show this help.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y) : ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

say()  { printf '%s\n' "$*"; }
hr()   { say "------------------------------------------------------------"; }
have() { command -v "$1" >/dev/null 2>&1; }

hr
say "pmkit: local model check    (Checked: 2026-10-17)"
say "Probes (localhost only, 3 second timeout each):"
say "  Ollama     GET $OLLAMA_URL"
say "  LM Studio  GET $LMSTUDIO_URL"
say "Files touched: none. Installs: none."
hr

if [ "$DRY_RUN" -eq 1 ]; then
  say "[dry-run] Would run:"
  say "  \$ curl -sf --noproxy '*' --max-time 3 $OLLAMA_URL"
  say "  \$ curl -sf --noproxy '*' --max-time 3 $LMSTUDIO_URL"
  hr
  exit 0
fi

if ! have curl; then
  say "Missing: curl. Install it with your package manager, or open the two URLs"
  say "above in a browser. A JSON reply means the server is running."
  exit 1
fi

# Pick a Python for JSON parsing, if one runs. Falls back to grep otherwise.
JSON_PY=""
for cand in python3 python; do
  if have "$cand" && "$cand" -c 'import json' >/dev/null 2>&1; then JSON_PY="$cand"; break; fi
done

# list_models <json> <list-key> <field>: prints <field> of each item in the
# top-level <list-key> array, one per line. Exits non-zero if it is not JSON
# of that shape (used to tell a model server from some other service).
list_models() {
  if [ -n "$JSON_PY" ]; then
    printf '%s' "$1" | "$JSON_PY" -c '
import json, sys
try:
    d = json.load(sys.stdin)
    items = d[sys.argv[1]]
    assert isinstance(items, list)
except Exception:
    sys.exit(3)
for it in items:
    if isinstance(it, dict) and isinstance(it.get(sys.argv[2]), str):
        print(it[sys.argv[2]])
' "$2" "$3" | tr -d '\r'
    return $?
  fi
  # No Python: rough fallback. The reply must contain a "<list-key>": [ array.
  # Values are scraped with grep and may include nested fields of the same name.
  printf '%s' "$1" | grep -q "\"$2\"[[:space:]]*:[[:space:]]*\[" || return 3
  printf '%s' "$1" | grep -oE "\"$3\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1  (rough list: no python found to parse JSON)/' || true
  return 0
}

probe() { curl -sf --noproxy '*' --max-time 3 "$1" 2>/dev/null; }

FOUND_ANY=0

say "Ollama"
if OUT="$(probe "$OLLAMA_URL")" && MODELS="$(list_models "$OUT" models name)"; then
  FOUND_ANY=1
  say "  Running at http://localhost:11434"
  if [ -n "$MODELS" ]; then
    say "  Models:"
    printf '%s\n' "$MODELS" | sed 's/^/    - /'
  else
    say "  No models listed. Pull one with: ollama pull <model>"
  fi
else
  say "  Not reachable. Start it with 'ollama serve' or the Ollama app, if installed."
fi
say ""

say "LM Studio"
if OUT="$(probe "$LMSTUDIO_URL")" && MODELS="$(list_models "$OUT" data id)"; then
  FOUND_ANY=1
  say "  Running at http://localhost:1234/v1"
  if [ -n "$MODELS" ]; then
    say "  Models:"
    printf '%s\n' "$MODELS" | sed 's/^/    - /'
  else
    say "  No models listed. Load a model in LM Studio and start its local server."
  fi
else
  say "  Not reachable. Start the local server in LM Studio, if installed."
fi
hr

say "Base URLs differ per tool. The /v1 suffix is the most common mistake:"
say "  LangExtract (Ollama)        http://localhost:11434        no /v1"
say "  graphify headless (Ollama)  http://localhost:11434/v1"
say "  Open Code Review (Ollama)   http://127.0.0.1:11434/v1"
say "  Strix (Ollama)              http://localhost:11434"
say "  LM Studio (any tool)        http://localhost:1234/v1"
say ""
say "Honest limits"
say "  - Tools that need tool calls or agent loops (Open Code Review, Strix) are"
say "    unreliable below about 30B parameters. Strix's docs say under 70B 'struggle'."
say "  - Local mode is the privacy option, not a free copy of a frontier model."
say "  - Run each tool's smoke test (guides/local-models.md) before relying on it."
if [ "$FOUND_ANY" -eq 0 ]; then
  say ""
  say "No local model server found. That is fine: Level 1 and 2 work without one."
fi
hr
