#!/usr/bin/env bash
# Assemble and install the Claude Code skill "project-setup".
#
# Layout written:
#   <dest>/project-setup/SKILL.md
#   <dest>/project-setup/references/{interview,catalog,guides}/
#   <dest>/project-setup/references/REPO_PATH.txt   (where this repo lives)
#   <dest>/project-setup/template/
#
# Default <dest> is ~/.claude/skills. --project <dir> uses <dir>/.claude/skills.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install-skill.sh [--project <dir>] [--dry-run] [--yes]

Installs the "project-setup" Claude Code skill.
  (default)        install to ~/.claude/skills/project-setup
  --project <dir>  install to <dir>/.claude/skills/project-setup (this project only)
  --dry-run        show what would happen, change nothing
  --yes            do not ask; replace an existing install
  -h, --help       show this help

Network calls: none. Files touched: only the install folder above.
EOF
}

PROJECT=""
DRY_RUN=0
YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --project)
      if [ $# -lt 2 ]; then echo "--project needs a directory" >&2; exit 2; fi
      PROJECT="$2"; shift 2 ;;
    --project=*) PROJECT="${1#--project=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes|-y) YES=1; shift ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

missing=0
for p in skill/project-setup/SKILL.md interview catalog guides template; do
  if [ ! -e "$REPO/$p" ]; then
    echo "Missing in repo: $p" >&2
    missing=1
  fi
done
if [ "$missing" -ne 0 ]; then
  echo "Cannot assemble the skill. Run this from a complete copy of the repo." >&2
  exit 1
fi

if [ -n "$PROJECT" ]; then
  if [ ! -d "$PROJECT" ]; then
    echo "Project directory does not exist: $PROJECT" >&2
    exit 1
  fi
  DEST="$(cd "$PROJECT" && pwd)/.claude/skills"
else
  if [ -z "${HOME:-}" ]; then
    echo "HOME is not set. Use --project <dir>." >&2
    exit 1
  fi
  DEST="$HOME/.claude/skills"
fi
SKILL_DIR="$DEST/project-setup"

echo "This will install the project-setup skill."
echo "  From: $REPO"
echo "  To:   $SKILL_DIR"
echo "  Copies: SKILL.md, interview/, catalog/, guides/ (into references/), template/"
echo "  Network calls: none"
echo

if [ -e "$SKILL_DIR" ]; then
  echo "An install already exists at: $SKILL_DIR"
  echo "Replacing it deletes that folder first, including any edits you made there."
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run: would ask before replacing it."
  elif [ "$YES" -eq 1 ]; then
    echo "--yes given: replacing."
  else
    if [ ! -t 0 ]; then
      echo "No terminal to ask. Re-run with --yes to replace, or remove the folder yourself." >&2
      exit 1
    fi
    printf "Replace the existing install? [y/N] "
    read -r answer || answer=""
    case "$answer" in
      y|Y|yes|YES|Yes) ;;
      *) echo "Left the existing install unchanged."; exit 0 ;;
    esac
  fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo
  echo "Dry run. Would create:"
  echo "  $SKILL_DIR/SKILL.md"
  echo "  $SKILL_DIR/references/interview/"
  echo "  $SKILL_DIR/references/catalog/"
  echo "  $SKILL_DIR/references/guides/"
  echo "  $SKILL_DIR/references/REPO_PATH.txt"
  echo "  $SKILL_DIR/template/"
  exit 0
fi

if [ -e "$SKILL_DIR" ]; then
  rm -rf -- "$SKILL_DIR"
fi
mkdir -p "$SKILL_DIR/references" "$SKILL_DIR/template"
cp "$REPO/skill/project-setup/SKILL.md" "$SKILL_DIR/SKILL.md"
for d in interview catalog guides; do
  mkdir -p "$SKILL_DIR/references/$d"
  cp -R "$REPO/$d/." "$SKILL_DIR/references/$d/"
done
cp -R "$REPO/template/." "$SKILL_DIR/template/"
find "$SKILL_DIR" -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
find "$SKILL_DIR" -type f -name '*.pyc' -exec rm -f {} + 2>/dev/null || true
REPO_NATIVE="$REPO"
if command -v cygpath >/dev/null 2>&1; then
  # Git Bash / Cygwin on Windows: store a path Windows tools understand.
  REPO_NATIVE="$(cygpath -m "$REPO")"
fi
printf '%s\n' "$REPO_NATIVE" > "$SKILL_DIR/references/REPO_PATH.txt"

count="$(find "$SKILL_DIR" -type f | wc -l | tr -d ' ')"
echo "Installed $count file(s) to $SKILL_DIR"
echo
echo "Next: start Claude Code in your project and ask it to set up the project,"
echo "or type /project-setup."
echo "The Level 2 installers stay in the repo: $REPO/levels/2-starter-tools/installers"
