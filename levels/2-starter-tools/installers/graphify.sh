#!/usr/bin/env bash
# pmkit Level 2 installer: graphify (PyPI package "graphifyy"), code-only mode.
# Checked: 2026-10-17. Read catalog/graphify.md and the upstream README first.
# This script asks before every step. It never asks for or stores API keys.
set -euo pipefail

TOOL="graphify"
DRY_RUN=0
ASSUME_YES=0
VERSION=""
VERSION_GIVEN=0

usage() {
  cat <<'EOF'
Usage: bash graphify.sh [--dry-run] [--yes] [--version <v>] [--help]

Installs the graphify CLI (PyPI package "graphifyy") for code-only graphs
and writes a privacy-safe env example to ./.pmkit/env/graphify.env.example.

  --dry-run   Print every step and command. Change nothing.
  --yes       Accept the core steps without asking. The two optional
              integration steps ("graphify install", "graphify hook install")
              are NOT covered by --yes. They always need a typed yes.
  --version <v>  Install exactly this version (for example 0.9.92).
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
      printf 'Invalid version: "%s". Use a release number such as %s.\n' "$VERSION" "0.9.92" >&2
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

# ask_explicit: like ask, but --yes does not answer it.
# --yes is checked first, so "--dry-run --yes" previews what "--yes" really does.
ask_explicit() {
  if [ "$ASSUME_YES" -eq 1 ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      say "[dry-run] Would skip: $1 (needs a typed yes, not covered by --yes)"
    else
      say "  Skipped: this step needs a typed yes and is not covered by --yes."
    fi
    return 1
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    say "[dry-run] Would ask: $1 [y/N] (showing the step as if yes)"
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
PKG="graphifyy"
if [ -n "$VERSION" ]; then PKG="graphifyy==$VERSION"; fi

# Pick an installer: uv first, pipx as fallback.
INSTALLER=""
if have uv; then INSTALLER="uv"; elif have pipx; then INSTALLER="pipx"; fi

hr
say "pmkit installer: graphify, code-only mode    (Checked: 2026-10-17)"
[ "$DRY_RUN" -eq 1 ] && say "DRY RUN: nothing will be installed or written."
hr
say "What it is: a CLI that builds a graph of your codebase. Code is parsed"
say "locally with tree-sitter and needs no LLM. Output goes to graphify-out/"
say "(graph.json, GRAPH_REPORT.md, graph.html). Docs, PDFs and images need an"
say "LLM pass; this script sets up code-only mode, which skips that."
say ""
say "Plan"
say "  Step 1  Install the CLI (exact package name, double y):"
say "            uv tool install $PKG      (fallback: pipx install $PKG)"
if [ -n "$VERSION" ]; then
  say "          Pinned to $VERSION (--version)."
else
  say "          No --version given: installs the latest release. Pin with --version <v>."
fi
say "  Step 2  Write a privacy-safe env example: $ENV_FILE"
say "            (GRAPHIFY_BACKEND=none = code-only, no LLM backend at all)"
say "  Optional, separate prompts, not covered by --yes:"
say "  Step 3  graphify install        (registers the /graphify skill)"
say "  Step 4  graphify hook install   (git hooks that rebuild the graph)"
say ""
say "Files and settings it touches"
say "  - Steps 1-2: uv/pipx tool folder in your home directory, and $ENV_FILE."
say "  - Step 3 and 4 touch more. Each is explained before it asks."
say "  - Running graphify later writes graphify-out/ in the folder you scan."
say ""
say "Network calls"
say "  - Install: downloads graphifyy and its dependencies from PyPI."
say "  - Code-only runs with GRAPHIFY_BACKEND=none: no LLM calls. No telemetry"
say "    code was found upstream."
say "  - Without GRAPHIFY_BACKEND=none, community labelling can send code symbol"
say "    names to an LLM, and falls back to 'claude -p' (your subscription) if"
say "    the claude CLI is on PATH."
say ""
say "API keys: none for code-only mode."
say ""
say "Warnings"
say "  - The PyPI name is 'graphifyy' (two y). Other graphify* packages are not"
say "    affiliated. Type it exactly."
say "  - The /graphify skill ignores GRAPHIFY_BACKEND. In skill mode it uses"
say "    Gemini if GEMINI_API_KEY or GOOGLE_API_KEY is set, otherwise your host"
say "    agent's model. For strictly local use, run the headless CLI."
say "  - Install prints an upsell for a paid cloud product. You do not need it."
hr

say "Checking prerequisites"
PREREQ_OK=1
if [ -n "$INSTALLER" ]; then
  say "  Found: $INSTALLER"
else
  say "  Missing: uv or pipx."
  say "  uv:   https://docs.astral.sh/uv/   pipx: https://pipx.pypa.io/"
  say "  graphify needs Python 3.10 or later. This script does not install prerequisites."
  PREREQ_OK=0
fi
if [ "$PREREQ_OK" -ne 1 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    INSTALLER="uv"
    say "[dry-run] A real run would stop here. Showing the uv commands."
  else
    exit 1
  fi
fi
hr

# Step 1
if [ "$INSTALLER" = "uv" ]; then
  INSTALL_CMD="uv tool install $PKG"
else
  INSTALL_CMD="pipx install $PKG"
fi
if ask "Step 1: install graphify with '$INSTALL_CMD'?"; then
  if [ "$INSTALLER" = "uv" ]; then
    run uv tool install "$PKG"
  else
    run pipx install "$PKG"
  fi
  say "  If graphifyy was already installed, check the output above: the old version"
  say "  may have been kept. To change versions, uninstall first (installers/README.md)."
else
  say "  Skipped step 1."
fi
hr

# Step 2
if ask "Step 2: write $ENV_FILE (privacy-safe settings, no keys)?"; then
  write_env_example <<'EOF'
# graphify privacy-safe settings (written by pmkit). Checked: 2026-10-17
# This is an example file. Copy the lines you want into your shell yourself.
# Never put API keys in this file.

# Code-only mode: disables every LLM backend, including the 'claude -p'
# community-labelling fallback. Code is parsed locally with tree-sitter.
GRAPHIFY_BACKEND=none

# Query logging is opt-in in the current code (the README says otherwise).
# This forces it off either way.
GRAPHIFY_QUERY_LOG_DISABLE=1

# Also: unset GEMINI_API_KEY and GOOGLE_API_KEY in this shell if docs must
# not go to Google. The /graphify skill uses Gemini when either is set.

# --- Optional local-model route (headless CLI only, NOT the /graphify skill) ---
# Uses a local Ollama server for the docs/PDF/image pass. Note the /v1 suffix.
# GRAPHIFY_BACKEND=ollama
# OLLAMA_BASE_URL=http://localhost:11434/v1
# OLLAMA_MODEL=qwen2.5-coder:7b
# Make sure the URL is localhost. LAN hosts are allowed with only a warning.
EOF
else
  say "  Skipped step 2."
fi
hr

# Step 3 (optional, explicit)
say "Step 3 (optional): graphify install"
say "  What it writes (for the default platform, Claude Code):"
say "  - Copies SKILL.md and a references/ folder to ~/.claude/skills/graphify/"
say "    (or under \$CLAUDE_CONFIG_DIR, or .claude/skills/ with --project)."
say "  - APPENDS a registration block to ~/.claude/CLAUDE.md"
say "    (or .claude/CLAUDE.md with --project)."
say "  - Writes a lock file under ~/.cache/graphify/skill-locks/."
say "  It does not detect your agent. Bare 'graphify install' targets Claude Code."
say "  On native Windows (for example Git Bash), bare install uses the 'windows'"
say "  platform variant. Its exact paths are unverified. Check the command output."
say "  For other agents use 'graphify install --platform <name>'."
say "  Reminder: the /graphify skill ignores GRAPHIFY_BACKEND (see warnings above)."
say "  You can skip this. The CLI works without it: graphify extract <folder>"
if [ "$DRY_RUN" -ne 1 ] && ! have graphify; then
  say "  graphify is not on PATH. Skipped step 3."
  say "  If step 1 ran, run 'uv tool update-shell' (or 'pipx ensurepath') and open a new shell."
elif ask_explicit "Run 'graphify install' now?"; then
  run graphify install
else
  say "  Skipped step 3."
fi
hr

# Step 4 (optional, explicit)
say "Step 4 (optional): graphify hook install"
say "  What it writes in the current git repo:"
say "  - Marker-delimited blocks in 4 git hooks: post-commit, post-checkout,"
say "    post-merge, post-rewrite (respects core.hooksPath and Husky)."
say "  - git config entries merge.graphify.* (a union merge driver for graph.json)."
say "  - Edits .gitattributes, which is a tracked file."
say "  After 'git pull' you still run 'graphify update .' yourself."
IN_GIT=0
if have git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then IN_GIT=1; fi
if [ "$IN_GIT" -ne 1 ] && [ "$DRY_RUN" -ne 1 ]; then
  say "  Not inside a git repository. Skipped step 4."
elif [ "$DRY_RUN" -ne 1 ] && ! have graphify; then
  say "  graphify is not on PATH. Skipped step 4."
  say "  If step 1 ran, run 'uv tool update-shell' (or 'pipx ensurepath') and open a new shell."
elif ask_explicit "Run 'graphify hook install' in $(pwd)?"; then
  run graphify hook install
else
  say "  Skipped step 4."
fi
hr

say "Installed version"
VER_LINE=""
if [ "$DRY_RUN" -eq 1 ]; then
  say "[dry-run] Would list the installed graphifyy version from $INSTALLER."
  [ -n "$VERSION" ] && say "[dry-run] Would check that it is $VERSION."
elif [ "$INSTALLER" = "uv" ]; then
  VER_LINE="$(uv tool list 2>/dev/null | grep -i '^graphifyy' | head -n 1 || true)"
else
  VER_LINE="$(pipx list 2>/dev/null | grep -i 'graphifyy' | head -n 1 || true)"
fi
if [ "$DRY_RUN" -ne 1 ]; then
  if [ -n "$VER_LINE" ]; then
    GOT="$(printf '%s' "$VER_LINE" | grep -oE '[0-9]+(\.[0-9]+)+[0-9A-Za-z.+-]*' | head -n 1 || true)"
    say "  $VER_LINE"
    say "  Record this exact version in the \"Installed tools\" table of SETUP_DECISIONS.md."
    say "  To install the same version again:  bash graphify.sh --version ${GOT:-<version>}"
    if [ -n "$VERSION" ] && [ "$GOT" != "$VERSION" ]; then
      say "  WARNING: you asked for $VERSION, but ${GOT:-another version} is installed."
    fi
  else
    say "  graphifyy not found in the $INSTALLER tool list."
  fi
fi
say ""
say "Next"
say "  1. Try it on a small folder first, in code-only mode:"
say "       GRAPHIFY_BACKEND=none graphify extract <folder>"
say "     Check 'graphify --help' for current flags. Releases come every few days."
say "  2. Record the tool, exact version, date and trigger in SETUP_DECISIONS.md."
say "  3. If LOG.md exists, log it:  python .pmkit/pmkit.py log --type TOOL-ADD --summary \"Added graphify <version> (code-only): <trigger>\""
say "  4. INFERRED edges are guesses. Do not mark them verified in knowledge/ without review."
hr
