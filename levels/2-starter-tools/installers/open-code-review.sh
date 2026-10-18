#!/usr/bin/env bash
# pmkit Level 2 installer: Open Code Review ("ocr"), delegation mode.
# Checked: 2026-10-17. Read catalog/open-code-review.md and the upstream README first.
# This script asks before every step. It never asks for or stores API keys.
set -euo pipefail

TOOL="open-code-review"
DRY_RUN=0
ASSUME_YES=0
VERSION=""
VERSION_GIVEN=0

usage() {
  cat <<'EOF'
Usage: bash open-code-review.sh [--dry-run] [--yes] [--version <v>] [--help]

Installs the Open Code Review CLI (ocr) from npm, prints the Claude Code
plugin commands for delegation mode, and writes a privacy-safe env example
to ./.pmkit/env/open-code-review.env.example.

  --dry-run   Print every step and command. Change nothing.
  --yes       Accept every step without asking (non-interactive).
  --version <v>  Install exactly this version (for example 1.13.1).
              Without it, the latest release is installed and the exact
              version is printed for you to record.
  --help      Show this help.

Run it from your project root.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --version)
      if [ $# -lt 2 ]; then printf 'Missing value for --version\n\n' >&2; usage >&2; exit 2; fi
      VERSION="$2"; VERSION_GIVEN=1; shift ;;
    --version=*) VERSION="${1#--version=}"; VERSION_GIVEN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# A version is digits first, then digits, letters, dots, + or -. A leading v is dropped.
VERSION="${VERSION#v}"
if [ "$VERSION_GIVEN" -eq 1 ]; then
  case "$VERSION" in
    ""|[!0-9]*|*[!0-9A-Za-z.+-]*)
      printf 'Invalid version: "%s". Use a release number such as %s.\n' "$VERSION" "1.13.1" >&2
      exit 2 ;;
  esac
fi

say()  { printf '%s\n' "$*"; }
hr()   { say "------------------------------------------------------------"; }
have() { command -v "$1" >/dev/null 2>&1; }

ask() {
  if [ "$DRY_RUN" -eq 1 ]; then
    say "[dry-run] Would ask: $1 [y/N] (showing the step as if yes)"
    return 0
  fi
  if [ "$ASSUME_YES" -eq 1 ]; then
    say "$1 [y/N] y (--yes)"
    return 0
  fi
  local reply=""
  printf '%s [y/N] ' "$1"
  read -r reply || reply=""
  case "$reply" in y|Y|yes|Yes|YES) return 0 ;; *) return 1 ;; esac
}

run() {
  say "  \$ $*"
  if [ "$DRY_RUN" -eq 1 ]; then return 0; fi
  "$@"
}

ENV_DIR="./.pmkit/env"
ENV_FILE="$ENV_DIR/$TOOL.env.example"

write_env_example() {
  if [ "$DRY_RUN" -eq 1 ]; then
    say "[dry-run] Would write $ENV_FILE with:"
    sed 's/^/    /'
    return 0
  fi
  if [ -e "$ENV_FILE" ]; then
    cat >/dev/null
    say "  $ENV_FILE already exists. Not changed."
    return 0
  fi
  mkdir -p "$ENV_DIR"
  cat >"$ENV_FILE"
  say "  Wrote $ENV_FILE"
}

# Package spec: pinned with --version, otherwise the latest release.
PKG="@alibaba-group/open-code-review"
if [ -n "$VERSION" ]; then PKG="@alibaba-group/open-code-review@$VERSION"; fi

hr
say "pmkit installer: Open Code Review (ocr), delegation mode    (Checked: 2026-10-17)"
[ "$DRY_RUN" -eq 1 ] && say "DRY RUN: nothing will be installed or written."
hr
say "What it is: a Go CLI for LLM review of git diffs, or of files with 'ocr scan'."
say "File selection and rule matching are plain code. In delegation mode OCR makes"
say "no LLM call: it hands the files and rules to your agent, and your agent reviews."
say ""
say "Plan"
say "  Step 1  Install the CLI globally:"
say "            npm i -g $PKG"
if [ -n "$VERSION" ]; then
  say "          Pinned to $VERSION (--version)."
else
  say "          No --version given: installs the latest release. Pin with --version <v>."
fi
say "  Step 2  Show the Claude Code plugin commands for delegation mode."
say "          You run them yourself inside Claude Code. This script does not."
say "  Step 3  Write a privacy-safe env example: $ENV_FILE"
say ""
say "Files and settings it touches"
say "  - Your global npm folder (adds the 'ocr' command)."
say "  - $ENV_FILE (new file; skipped if it exists)."
say "  - It does NOT create ~/.opencodereview/config.json. You decide on that."
say ""
say "Network calls"
say "  - Install: downloads the package from the npm registry."
say "  - Delegation mode: none on the OCR side. Your agent's normal model calls apply."
say "  - Default (non-delegation) mode: diffs and file contents go to the LLM"
say "    provider you configure. Many built-in presets are hosted in China."
say "    Choose a provider on purpose."
say "  - Telemetry is off by default (opt-in with OCR_ENABLE_TELEMETRY=1)."
say ""
say "API keys: none for delegation mode."
say ""
say "Warning: if OCR's own LLM is not configured, it looks in this order:"
say "  ~/.opencodereview/config.json, then OCR_LLM_URL/OCR_LLM_TOKEN/OCR_LLM_MODEL,"
say "  then it SILENTLY reuses ANTHROPIC_BASE_URL/ANTHROPIC_AUTH_TOKEN/ANTHROPIC_MODEL."
say "  So a non-delegation run can bill or route through your Claude Code settings."
hr

say "Checking prerequisites"
PREREQ_OK=1
if have npm; then
  say "  npm: $(npm --version 2>/dev/null || echo unknown)"
else
  say "  Missing: npm (comes with Node.js). Get it from https://nodejs.org/"
  PREREQ_OK=0
fi
if have git; then
  GIT_VER="$(git --version 2>/dev/null | sed 's/[^0-9.]*\([0-9][0-9.]*\).*/\1/')"
  GIT_MAJOR="$(printf '%s' "$GIT_VER" | cut -d. -f1)"
  GIT_MINOR="$(printf '%s' "$GIT_VER" | cut -d. -f2)"
  say "  git: $GIT_VER"
  if [ "${GIT_MAJOR:-0}" -lt 2 ] 2>/dev/null || { [ "${GIT_MAJOR:-0}" -eq 2 ] && [ "${GIT_MINOR:-0}" -lt 41 ]; } 2>/dev/null; then
    say "  OCR needs git 2.41 or later. Update git from https://git-scm.com/"
    PREREQ_OK=0
  fi
else
  say "  Missing: git 2.41 or later. Get it from https://git-scm.com/"
  PREREQ_OK=0
fi
say "  Other install routes upstream: 'brew install open-code-review', or a release"
say "  binary checked against sha256sum.txt."
if [ "$PREREQ_OK" -ne 1 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    say "[dry-run] A real run would stop here."
  else
    say "  This script does not install prerequisites."
    exit 1
  fi
fi
hr

# Step 1
if ask "Step 1: install ocr with 'npm i -g $PKG'?"; then
  run npm i -g "$PKG"
else
  say "  Skipped step 1."
fi
hr

# Step 2
if ask "Step 2: show the Claude Code plugin commands for delegation mode?"; then
  say "  Run these inside Claude Code (type them at the Claude Code prompt):"
  say ""
  say "    /plugin marketplace add alibaba/open-code-review"
  say "    /plugin install open-code-review@open-code-review"
  say ""
  say "  This adds two commands:"
  say "    /open-code-review:delegate-review   delegation mode: your agent reviews, no OCR key"
  say "    /open-code-review:review            uses OCR's own LLM (see the warning above)"
  say "  Use delegate-review unless you have set up OCR's own provider on purpose."
  say ""
  say "  Other agents: the delegate skill installs with"
  say "    npx skills add alibaba/open-code-review --skill open-code-review-delegate"
  say "    (npx fetches the latest 'skills' CLI from npm, not pinned, and may prompt.)"
  say "  Plain CLI delegation (no plugin):"
  say "    ocr delegate preview --format json"
  say "    ocr delegate rule --format json <files>"
else
  say "  Skipped step 2."
fi
hr

# Step 3
if ask "Step 3: write $ENV_FILE (privacy-safe settings, no keys)?"; then
  write_env_example <<'EOF'
# Open Code Review privacy-safe settings (written by pmkit). Checked: 2026-10-17
# This is an example file. Copy the lines you want into your shell yourself.
# Never put real API keys in this file.

# Recommended: delegation mode (/open-code-review:delegate-review or
# 'ocr delegate ...'). OCR makes no LLM call, so nothing below is needed.

# Telemetry and content logging are off by default. Leave these unset:
#   OCR_ENABLE_TELEMETRY
#   OCR_CONTENT_LOGGING

# If you run OCR's own LLM, configure it explicitly so it does not fall back
# to ANTHROPIC_BASE_URL / ANTHROPIC_AUTH_TOKEN / ANTHROPIC_MODEL.

# --- Optional local-model route (Ollama, OpenAI protocol, note the /v1) ---
# The model must emit native tool calls (qwen3 works; deepseek-r1 fails with
# "No tool calls parsed"). Expect to need a large model (about 30B+).
# OCR_LLM_URL=http://127.0.0.1:11434/v1
# OCR_LLM_TOKEN=ollama            # placeholder; must be non-empty
# OCR_LLM_MODEL=qwen3:32b
# OCR_LLM_PROTOCOL=openai
# OCR_LLM_TIMEOUT=600             # default 300 s; raise for slow local models
# LM Studio (http://localhost:1234/v1) is undocumented upstream: untested.
EOF
else
  say "  Skipped step 3."
fi
hr

say "Installed version"
if [ "$DRY_RUN" -eq 1 ]; then
  say "[dry-run] Would run: npm ls -g @alibaba-group/open-code-review --depth=0"
  [ -n "$VERSION" ] && say "[dry-run] Would check that it is $VERSION."
else
  VER_LINE="$(npm ls -g @alibaba-group/open-code-review --depth=0 2>/dev/null | grep -i 'open-code-review' | head -n 1 || true)"
  if [ -n "$VER_LINE" ]; then
    GOT="$(printf '%s' "$VER_LINE" | sed 's/.*open-code-review@//; s/[[:space:]].*//')"
    say "  $VER_LINE"
    say "  Record this exact version in the \"Installed tools\" table of SETUP_DECISIONS.md."
    say "  To install the same version again:  bash open-code-review.sh --version ${GOT:-<version>}"
    if [ -n "$VERSION" ] && [ "$GOT" != "$VERSION" ]; then
      say "  WARNING: you asked for $VERSION, but ${GOT:-another version} is installed."
    fi
  else
    say "  Package not found in the global npm folder."
  fi
fi
say ""
say "Next"
say "  1. Smoke test on a 1-line change: make a small edit, then run the delegate"
say "     review in your agent."
say "  2. Record the tool, exact version, date and trigger in SETUP_DECISIONS.md."
say "  3. If LOG.md exists, log it:  python .pmkit/pmkit.py log --type TOOL-ADD --summary \"Added Open Code Review <version> (delegation): <trigger>\""
hr
