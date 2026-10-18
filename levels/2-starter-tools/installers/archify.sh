#!/usr/bin/env bash
# pmkit Level 2 installer: Archify (agent skill that renders validated diagrams).
# Checked: 2026-10-17. Read catalog/archify.md and the upstream README first.
# This script asks before every step. It never asks for or stores API keys.
set -euo pipefail

TOOL="archify"
DRY_RUN=0
ASSUME_YES=0
VERSION=""
VERSION_GIVEN=0

usage() {
  cat <<'EOF'
Usage: bash archify.sh [--dry-run] [--yes] [--version <v>] [--help]

Installs the Archify agent skill and writes a privacy-safe env example
to ./.pmkit/env/archify.env.example in the current directory.

  --dry-run   Print every step and command. Change nothing.
  --yes       Accept every step without asking (non-interactive).
  --version <v>  Check that the installed Archify is exactly this version
              (for example 3.1.0). The install route cannot pick a release,
              so a mismatch is reported and the script exits with code 3.
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
      printf 'Invalid version: "%s". Use a release number such as %s.\n' "$VERSION" "3.1.0" >&2
      exit 2 ;;
  esac
fi

say()  { printf '%s\n' "$*"; }
hr()   { say "------------------------------------------------------------"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ask "question" -> 0 = yes, 1 = no. Default answer is No.
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

# run cmd args... -> prints the command; runs it unless --dry-run.
run() {
  say "  \$ $*"
  if [ "$DRY_RUN" -eq 1 ]; then return 0; fi
  "$@"
}

ENV_DIR="./.pmkit/env"
ENV_FILE="$ENV_DIR/$TOOL.env.example"

# write_env_example: content comes from stdin. Never overwrites.
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

hr
say "pmkit installer: Archify    (Checked: 2026-10-17)"
[ "$DRY_RUN" -eq 1 ] && say "DRY RUN: nothing will be installed or written."
hr
say "What it is: an agent skill. Your agent writes typed JSON for one diagram"
say "type. Archify's Node validators check it and 'deliver' writes one"
say "self-contained HTML file. Archify makes no LLM calls itself."
say ""
say "Plan"
say "  Step 1  Install the skill globally:"
say "            npx skills add tt-a1i/archify -g"
say "          npx fetches the latest 'skills' CLI from npm (not pinned)."
say "          The skills CLI installs the current Archify release. It has no"
say "          documented way to pick an older one, so this script cannot pin it."
if [ -n "$VERSION" ]; then
  say "          --version $VERSION: after install, the script checks the installed"
  say "          version and exits with code 3 if it is not $VERSION."
fi
say "          npx may ask 'Ok to proceed?' and the skills CLI may ask which"
say "          agents to install for. --yes does not answer those prompts."
say "  Step 2  Write a privacy-safe env example:"
say "            $ENV_FILE"
say ""
say "Files and settings it touches"
say "  - Your agent's global skills folder (for Claude Code: ~/.claude/skills/)."
say "    The skills CLI picks the exact folder."
say "  - $ENV_FILE (new file; skipped if it exists)."
say "  - Nothing else. No shell profile, no git config."
say ""
say "Network calls"
say "  - Install: npx downloads the 'skills' CLI from the npm registry and"
say "    fetches the skill from github.com/tt-a1i/archify."
say "  - Runtime: one optional update-check GET to"
say "    https://tt-a1i.github.io/archify/skill-updates/archify/stable.json"
say "    It sends no project data. The server still sees your IP and the time."
say "    ARCHIFY_UPDATE_CHECK_DISABLED=1 turns it off."
say "  - Delivered HTML can contain external links. They load only when clicked."
say ""
say "API keys: none. Archify uses whatever model your agent uses."
say ""
say "Before you install"
say "  - Read archify/SKILL.md upstream. A skill gives instructions to your agent."
say "  - The upstream README has a sponsors section that promotes discounted API"
say "    reseller services. Archify does not need them. Do not route keys through them."
say "  - Small or local models may fail Archify's JSON validation (undocumented)."
hr

# Prerequisites
say "Checking prerequisites"
PREREQ_OK=1
if have node && have npx; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  say "  node: $(node --version 2>/dev/null || echo unknown)"
  if [ "$NODE_MAJOR" -lt 18 ] 2>/dev/null; then
    say "  Node.js 18 or later is required. Update Node.js from https://nodejs.org/"
    PREREQ_OK=0
  fi
else
  say "  Missing: Node.js with npx (version 18 or later)."
  say "  Get it from https://nodejs.org/ or your package manager. This script does not install it."
  PREREQ_OK=0
fi
if [ "$PREREQ_OK" -ne 1 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    say "[dry-run] A real run would stop here."
  else
    exit 1
  fi
fi
hr

# Step 1
INSTALLED_NOW=0
if ask "Step 1: install the Archify skill with 'npx skills add tt-a1i/archify -g'?"; then
  run npx skills add tt-a1i/archify -g
  INSTALLED_NOW=1
else
  say "  Skipped step 1."
fi
hr

# Step 2
if ask "Step 2: write $ENV_FILE (privacy-safe settings, no keys)?"; then
  write_env_example <<'EOF'
# Archify privacy-safe settings (written by pmkit). Checked: 2026-10-17
# This is an example file. Copy the lines you want into your shell or agent
# environment yourself. Never put API keys in this file.

# Turns off the only outbound request Archify makes (the update-check GET)
# and the reminder-state writes.
ARCHIFY_UPDATE_CHECK_DISABLED=1
EOF
else
  say "  Skipped step 2."
fi
hr

# Version
say "Installed version"
FOUND=""
for d in "$HOME/.claude/skills/archify" "$HOME/.agents/skills/archify" "$HOME/.config/opencode/skills/archify" "./.claude/skills/archify"; do
  if [ -f "$d/package.json" ]; then FOUND="$d"; break; fi
done
PIN_FAILED=0
if [ "$DRY_RUN" -eq 1 ]; then
  say "[dry-run] Would read the version from archify/package.json in your skills folder."
  [ -n "$VERSION" ] && say "[dry-run] Would check that it is $VERSION."
elif [ -n "$FOUND" ] && have node; then
  VER="$(node -p "require(process.argv[1]).version" "$FOUND/package.json" 2>/dev/null || echo unknown)"
  say "  Archify $VER  ($FOUND)"
  say "  Record this exact version in the \"Installed tools\" table of SETUP_DECISIONS.md."
  if [ -f "$FOUND/bin/archify.mjs" ]; then
    say "  Self-check you can run:  node \"$FOUND/bin/archify.mjs\" doctor"
  fi
  if [ -n "$VERSION" ] && [ "$VER" != "$VERSION" ]; then
    say "  WARNING: you asked for $VERSION, but $VER is installed."
    say "  For an exact release, use the clone route from the upstream README with"
    say "  that release's tag (GitHub Releases list tags such as v3.1.0), or remove"
    say "  this install (see installers/README.md, Removing a tool)."
    PIN_FAILED=1
  fi
else
  say "  Could not find archify/package.json in the usual skills folders."
  say "  Look in your agent's skills folder and read the 'version' field."
  if [ -n "$VERSION" ] && [ "$INSTALLED_NOW" -eq 1 ]; then
    say "  WARNING: could not check that the installed version is $VERSION."
    PIN_FAILED=1
  fi
fi
say ""
say "Next"
say "  1. Record the tool, exact version, date and trigger in SETUP_DECISIONS.md."
say "  2. If LOG.md exists, log it:  python .pmkit/pmkit.py log --type TOOL-ADD --summary \"Added Archify <version>: <trigger>\""
say "  3. Set a revisit date. Remove it if nobody reads the diagrams."
hr
if [ "$PIN_FAILED" -eq 1 ]; then exit 3; fi
