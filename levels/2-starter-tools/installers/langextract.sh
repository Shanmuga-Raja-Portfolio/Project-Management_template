#!/usr/bin/env bash
# pmkit Level 2 installer: LangExtract (Python library for grounded extraction).
# Checked: 2026-10-17. Read catalog/langextract.md and the upstream README first.
# This script asks before every step. It never asks for or stores API keys.
set -euo pipefail

TOOL="langextract"
DRY_RUN=0
ASSUME_YES=0
VERSION=""
VERSION_GIVEN=0
VENV_DIR="./.pmkit/venv-langextract"

usage() {
  cat <<'EOF'
Usage: bash langextract.sh [--dry-run] [--yes] [--version <v>] [--help]

Installs the LangExtract Python library, by default into a project venv at
./.pmkit/venv-langextract, and writes a privacy-safe env example to
./.pmkit/env/langextract.env.example.

  --dry-run   Print every step and command. Change nothing.
  --yes       Accept every step without asking (uses the venv).
  --version <v>  Install exactly this version (for example 1.7.1).
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
      printf 'Invalid version: "%s". Use a release number such as %s.\n' "$VERSION" "1.7.1" >&2
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

# ask_explicit: used for the "install into your current Python" fallback.
# --yes does not answer it, because --yes means "use the venv".
ask_explicit() {
  if [ "$DRY_RUN" -eq 1 ]; then
    say "[dry-run] Would ask: $1 [y/N]"
    return 1
  fi
  if [ "$ASSUME_YES" -eq 1 ]; then return 1; fi
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

# Find a real Python 3.10+ (skips store stubs that fail to run).
# On Git Bash/MSYS, "python3" is often the Microsoft Store alias, so try
# "python" first there.
PY=""
PY_CANDIDATES="python3 python"
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*) PY_CANDIDATES="python python3" ;;
esac
for cand in $PY_CANDIDATES; do
  if have "$cand" && "$cand" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1; then
    PY="$cand"; break
  fi
done

# Package spec: pinned with --version, otherwise the latest release.
PKG="langextract"
PKG_OPENAI="langextract[openai]"
if [ -n "$VERSION" ]; then PKG="langextract==$VERSION"; PKG_OPENAI="langextract[openai]==$VERSION"; fi

hr
say "pmkit installer: LangExtract    (Checked: 2026-10-17)"
[ "$DRY_RUN" -eq 1 ] && say "DRY RUN: nothing will be installed or written."
hr
say "What it is: a Python library. lx.extract() pulls entities out of text using"
say "a prompt and a few examples, and records the character span each one came"
say "from, so a person can check it. Items it cannot align get no span."
say "It is a library you call from a script, not a CLI or a service."
say ""
say "Plan"
say "  Step 1  Create a project venv:  ${PY:-python3} -m venv $VENV_DIR"
say "          (if you say no, you can install into your current Python instead)"
say "  Step 2  Install:  python -m pip install $PKG   (inside the venv)"
if [ -n "$VERSION" ]; then
  say "          Pinned to $VERSION (--version)."
else
  say "          No --version given: installs the latest release. Pin with --version <v>."
fi
say "  Step 3  Write a privacy-safe env example: $ENV_FILE"
say ""
say "Files and settings it touches"
say "  - $VENV_DIR (new folder). Keep it out of git: the kit .gitignore already lists .pmkit/venv-*/; add that line if you use your own .gitignore."
say "  - $ENV_FILE (new file; skipped if it exists)."
say ""
say "Network calls"
say "  - Install: downloads from PyPI. The core install also pulls google-genai"
say "    and google-cloud-storage, even if you only use Ollama."
say "  - Runtime: your text goes to whichever model you call. Gemini or OpenAI:"
say "    it leaves the machine. Local Ollama: it stays local."
say ""
say "API keys: none for local Ollama. Cloud models read GEMINI_API_KEY (then"
say "LANGEXTRACT_API_KEY) or OPENAI_API_KEY (then LANGEXTRACT_API_KEY)."
say "Set those yourself if you need them. This script never asks for them."
say ""
say "Notes"
say "  - Ollama has JSON mode only, no strict output schema. Leave fence_output"
say "    and use_schema_constraints unset."
say "  - Cost grows with document length x extraction_passes."
say "  - Health-related use is also under the Health AI Developer Foundations terms."
hr

say "Checking prerequisites"
PREREQ_OK=1
if [ -n "$PY" ]; then
  say "  python: $("$PY" --version 2>&1)"
else
  say "  Missing: Python 3.10 or later. Get it from https://www.python.org/downloads/"
  say "  This script does not install it."
  PREREQ_OK=0
fi
if [ "$PREREQ_OK" -ne 1 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    PY="python3"
    say "[dry-run] A real run would stop here."
  else
    exit 1
  fi
fi
hr

# Step 1: venv (or fallback)
TARGET_PY=""
venv_python() {
  if [ -x "$VENV_DIR/bin/python" ]; then printf '%s' "$VENV_DIR/bin/python"
  elif [ -x "$VENV_DIR/Scripts/python.exe" ]; then printf '%s' "$VENV_DIR/Scripts/python.exe"
  fi
}
create_venv() {
  say "  \$ $PY -m venv $VENV_DIR"
  if [ "$DRY_RUN" -eq 1 ]; then return 0; fi
  if ! "$PY" -m venv "$VENV_DIR"; then
    rm -rf "$VENV_DIR"
    say "  Creating the venv failed. Removed the partial $VENV_DIR."
    say "  Common cause: ensurepip is missing (Debian/Ubuntu: install python3-venv)."
    exit 1
  fi
}
USE_VENV=0
if [ -e "$VENV_DIR" ] && [ "$DRY_RUN" -ne 1 ]; then
  VPY="$(venv_python)"
  if [ -n "$VPY" ] && "$VPY" -m pip --version >/dev/null 2>&1; then
    say "Step 1: $VENV_DIR already exists and has pip. Reusing it."
    USE_VENV=1
  else
    say "Step 1: $VENV_DIR exists but is broken (no python or no pip inside)."
    if ask "  Delete it and create a new venv?"; then
      rm -rf "$VENV_DIR"
      create_venv
      USE_VENV=1
    fi
  fi
elif ask "Step 1: create a venv at $VENV_DIR?"; then
  create_venv
  USE_VENV=1
fi
if [ "$USE_VENV" -eq 1 ]; then
  TARGET_PY="$(venv_python)"
  if [ -n "$TARGET_PY" ]; then
    :
  elif [ "$DRY_RUN" -eq 1 ]; then
    TARGET_PY="$VENV_DIR/bin/python"
  else
    say "  Could not find python inside $VENV_DIR."
    exit 1
  fi
else
  say "  No venv."
  if ask_explicit "Install into your current Python instead ($(command -v "$PY"))?"; then
    TARGET_PY="$PY"
  else
    say "  Skipped steps 1-2. To install by hand later:  python -m pip install \"$PKG\""
  fi
fi
hr

# Step 2: install
if [ -n "$TARGET_PY" ]; then
  if ask "Step 2: install langextract with '$TARGET_PY -m pip install $PKG'?"; then
    run "$TARGET_PY" -m pip install "$PKG"
    say "  For OpenAI support later: $TARGET_PY -m pip install \"$PKG_OPENAI\""
  else
    say "  Skipped step 2."
  fi
  hr
fi

# Step 3: env example
if ask "Step 3: write $ENV_FILE (privacy-safe settings, no keys)?"; then
  write_env_example <<'EOF'
# LangExtract privacy-safe settings (written by pmkit). Checked: 2026-10-17
# This is an example file. Copy the lines you want into your shell yourself.
# Never put real API keys in this file.

# --- Local route: Ollama native API. NO /v1 suffix here. ---
# LangExtract reads OLLAMA_BASE_URL in code (not in the README).
# You can pass model_url="http://localhost:11434" in code instead.
OLLAMA_BASE_URL=http://localhost:11434
# Use model_id="gemma2:2b" or larger. Recall drops with small models.
# JSON mode only on Ollama: leave fence_output / use_schema_constraints unset.

# --- LM Studio / other OpenAI-compatible server (untested upstream) ---
# In code: lx.factory.ModelConfig(model_id="<name>", provider="openai",
#   provider_kwargs={"base_url": "http://localhost:1234/v1", "api_key": "lm-studio"})
# Pass api_key explicitly: env lookup only matches gpt* model ids.

# --- Cloud keys: set them in your shell yourself if you choose a cloud model ---
# GEMINI_API_KEY / LANGEXTRACT_API_KEY / OPENAI_API_KEY
# With a cloud model, your documents leave this machine.
EOF
else
  say "  Skipped step 3."
fi
hr

say "Installed version"
if [ "$DRY_RUN" -eq 1 ]; then
  say "[dry-run] Would read the langextract version from the chosen Python."
  [ -n "$VERSION" ] && say "[dry-run] Would check that it is $VERSION."
elif [ -n "$TARGET_PY" ]; then
  GOT="$("$TARGET_PY" -c 'import importlib.metadata as m; print(m.version("langextract"))' 2>/dev/null || true)"
  if [ -n "$GOT" ]; then
    say "  langextract $GOT"
    say "  Record this exact version in the \"Installed tools\" table of SETUP_DECISIONS.md."
    say "  To install the same version again:  bash langextract.sh --version $GOT"
    if [ -n "$VERSION" ] && [ "$GOT" != "$VERSION" ]; then
      say "  WARNING: you asked for $VERSION, but $GOT is installed."
    fi
  else
    say "  langextract is not installed in $TARGET_PY."
  fi
else
  say "  Not installed by this run."
fi
say ""
say "Next"
say "  1. Run the one-sentence smoke test in guides/local-models.md before"
say "     relying on the local route."
say "  2. Record the tool, exact version, date and trigger in SETUP_DECISIONS.md."
say "  3. If LOG.md exists, log it:  python .pmkit/pmkit.py log --type TOOL-ADD --summary \"Added LangExtract <version>: <trigger>\""
hr
