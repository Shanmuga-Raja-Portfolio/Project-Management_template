#!/usr/bin/env bash
# Copy the pmkit starter folder (template/) into a project directory.
# Existing files are never overwritten: they are skipped and reported.
#
# Usage: scripts/new-project.sh [--minimal | --only <list>] [--dry-run] [--yes] <target-dir>
set -euo pipefail

REPO_URL="https://github.com/Shanmuga-Raja-Portfolio/Project-Management_template"
MINIMAL_SET="RULES.md,AGENTS.md,PROJECT.md,STATUS.md,SETUP_DECISIONS.md,.gitignore,.pmkit/"

usage() {
  cat <<'EOF'
Usage: new-project.sh [--minimal | --only <list>] [--dry-run] [--yes] <target-dir>

Copies the pmkit starter files from template/ into <target-dir>.
- Creates <target-dir> if it does not exist.
- Never overwrites an existing file. Existing files are skipped and listed.
  For an existing .gitignore it prints the lines you may want to add.

Options:
  --minimal       copy only RULES.md, AGENTS.md, PROJECT.md, STATUS.md,
                  SETUP_DECISIONS.md, .gitignore and .pmkit/
  --only <list>   copy only these files or folders (comma-separated, relative
                  to template/), e.g. for a browser chat window set:
                  --only PROJECT.md,STATUS.md,RULES.md,SETUP_DECISIONS.md
  --dry-run       show what would be created, change nothing
  --yes           apply the prune step without asking (its dry run is
                  still shown first)
  -h, --help      show this help

Without --minimal or --only, the whole starter folder is copied.

If .pmkit/ was copied, it then runs "python .pmkit/pmkit.py prune --dry-run"
in <target-dir> and shows which instruction lines point to files you did not
copy. It removes them after a yes (or with --yes). With no terminal to ask
and no --yes, it prunes nothing and prints the command. It runs
"pmkit.py sync" only if a line in .pmkit/adapters.txt is enabled (none is by
default). If no Python 3.8+ is found, it prints the commands to run instead.
EOF
}

TARGET=""
DRY_RUN=0
YES=0
ONLY=""
MODE="full"
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes|-y) YES=1; shift ;;
    --minimal)
      if [ "$MODE" = "only" ]; then echo "Use --minimal or --only, not both." >&2; exit 2; fi
      MODE="minimal"; ONLY="$MINIMAL_SET"; shift ;;
    --only)
      if [ $# -lt 2 ] || [ -z "$2" ]; then echo "--only needs a comma-separated list" >&2; exit 2; fi
      if [ "$MODE" = "minimal" ]; then echo "Use --minimal or --only, not both." >&2; exit 2; fi
      MODE="only"; ONLY="$2"; shift 2 ;;
    --only=*)
      if [ "$MODE" = "minimal" ]; then echo "Use --minimal or --only, not both." >&2; exit 2; fi
      MODE="only"; ONLY="${1#--only=}"
      if [ -z "$ONLY" ]; then echo "--only needs a comma-separated list" >&2; exit 2; fi
      shift ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$TARGET" ]; then
        echo "Only one target directory is allowed." >&2; exit 2
      fi
      TARGET="$1"; shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SRC="$REPO/template"

if [ ! -d "$SRC" ]; then
  echo "Cannot find the template folder at: $SRC" >&2
  exit 1
fi

# Parse the selection into normalised entries (no leading ./, no trailing /).
SELECT=()
if [ "$MODE" != "full" ]; then
  IFS=',' read -r -a raw <<< "$ONLY"
  for e in "${raw[@]}"; do
    e="$(printf '%s' "$e" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's#\\#/#g' -e 's#^\./##' -e 's#/*$##')"
    case "$e" in template/*) e="${e#template/}" ;; esac
    [ -z "$e" ] && continue
    case "$e" in
      /*|..|../*|*/..|*/../*)
        echo "--only: not a path inside template/: $e" >&2; exit 2 ;;
    esac
    if [ ! -e "$SRC/$e" ]; then
      echo "--only: not in template/: $e" >&2
      echo "Available: $(cd "$SRC" && ls -A | tr '\n' ' ')" >&2
      exit 2
    fi
    SELECT+=("$e")
  done
  if [ "${#SELECT[@]}" -eq 0 ]; then
    echo "--only: the list is empty." >&2; exit 2
  fi
fi

selected() {
  [ "$MODE" = "full" ] && return 0
  local rel="$1" e
  for e in "${SELECT[@]}"; do
    if [ "$rel" = "$e" ]; then return 0; fi
    case "$rel" in "$e"/*) return 0 ;; esac
  done
  return 1
}

if [ -e "$TARGET" ] && [ ! -d "$TARGET" ]; then
  echo "Target exists and is not a directory: $TARGET" >&2
  exit 1
fi

# Absolute, physical path of the target, without creating anything: resolve
# the nearest existing parent and append the parts that do not exist yet.
EXISTING="$TARGET"
REST=""
while [ ! -d "$EXISTING" ]; do
  REST="/$(basename "$EXISTING")$REST"
  PARENT="$(dirname "$EXISTING")"
  if [ "$PARENT" = "$EXISTING" ]; then break; fi
  EXISTING="$PARENT"
done
EXISTING_ABS="$(cd "$EXISTING" && pwd -P)"
TARGET_ABS="${EXISTING_ABS%/}$REST"
if [ -z "$TARGET_ABS" ]; then TARGET_ABS="/"; fi

# Refuse a target inside template/ before creating anything. Compare every
# existing ancestor of the target with template/ as the same directory
# (-ef), which also works on case-insensitive file systems and through
# symlinks. Parts that do not exist yet cannot be template/ itself.
inside_template=0
dir="$EXISTING_ABS"
while :; do
  if [ "$dir" -ef "$SRC" ]; then inside_template=1; break; fi
  up="$(dirname "$dir")"
  if [ "$up" = "$dir" ]; then break; fi
  dir="$up"
done
case "${TARGET_ABS%/}/" in
  "$SRC/"*) inside_template=1 ;;
esac
if [ "$inside_template" -eq 1 ]; then
  echo "Target is inside the template folder. Pick another directory." >&2
  exit 1
fi

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$TARGET_ABS"
fi

# Split a .gitignore pattern into globals: GI_PAT (no "!", no leading "/" or
# "**/", no trailing "/"), GI_NEG (1 for "!x"), GI_DIR (1 for a trailing "/",
# directories only) and GI_ANCHOR (1 if it has a "/" before the end, so it
# matches from the root; 0 means it matches a name at any depth).
gitignore_parse() {
  local p="$1"
  GI_NEG=0; GI_DIR=0; GI_ANCHOR=0
  case "$p" in '!'*) GI_NEG=1; p="${p#!}" ;; esac
  case "$p" in */) GI_DIR=1; p="${p%/}" ;; esac
  case "$p" in '**/'*) p="${p#\*\*/}" ;; */*) GI_ANCHOR=1; p="${p#/}" ;; esac
  case "$p" in */*) GI_ANCHOR=1 ;; esac
  GI_PAT="$p"
}

# True if a line in the existing .gitignore ($1) already covers the suggested
# line ($2) by meaning, not only by spelling: ".env*" covers ".env", "*.env"
# covers ".pmkit/env/*.env". A negation ("!x") is covered only by a negation;
# a root-only or directory-only line does not cover a wider one.
gitignore_covers() {
  local have w_pat w_neg w_dir w_anchor rest prefix part last
  gitignore_parse "$2"
  w_pat="$GI_PAT"; w_neg="$GI_NEG"; w_dir="$GI_DIR"; w_anchor="$GI_ANCHOR"
  while IFS= read -r have || [ -n "$have" ]; do
    have="${have%$'\r'}"
    have="$(printf '%s' "$have" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    case "$have" in ''|'#'*) continue ;; esac
    gitignore_parse "$have"
    [ "$GI_NEG" -eq "$w_neg" ] || continue
    # Ignoring a parent folder covers everything in it, so test the whole
    # path and each parent: an anchored line against "a", "a/b", ...; a
    # name-only line against each part.
    rest="$w_pat"; prefix=""
    while :; do
      part="${rest%%/*}"
      if [ "$part" = "$rest" ]; then last=1; rest=""; else last=0; rest="${rest#*/}"; fi
      prefix="${prefix:+$prefix/}$part"
      if [ "$last" -eq 0 ] || [ "$GI_DIR" -eq 0 ] || [ "$w_dir" -eq 1 ]; then
        if [ "$GI_ANCHOR" -eq 1 ]; then
          if [ "$w_anchor" -eq 1 ]; then
            [ "$GI_PAT" = "$prefix" ] && return 0
            # shellcheck disable=SC2254
            case "$prefix" in $GI_PAT) return 0 ;; esac
          fi
        else
          [ "$GI_PAT" = "$part" ] && return 0
          # shellcheck disable=SC2254
          case "$part" in $GI_PAT) return 0 ;; esac
        fi
      fi
      [ "$last" -eq 1 ] && break
    done
  done < "$1"
  return 1
}

created=()
skipped=()
gitignore_add=()

while IFS= read -r -d '' file; do
  rel="${file#"$SRC"/}"
  case "$rel" in
    *__pycache__*|*.pyc) continue ;;
  esac
  selected "$rel" || continue
  dest="$TARGET_ABS/$rel"
  if [ -e "$dest" ]; then
    skipped+=("$rel")
    if [ "$rel" = ".gitignore" ] && [ -f "$dest" ]; then
      while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        case "$line" in ''|'#'*) continue ;; esac
        case "$line" in
          .pmkit/*|'!.pmkit/'*) selected ".pmkit/pmkit.py" || continue ;;
        esac
        if ! gitignore_covers "$dest" "$line"; then
          gitignore_add+=("$line")
        fi
      done < "$file"
    fi
    continue
  fi
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$file" "$dest"
  fi
  created+=("$rel")
done < <(find "$SRC" -type f -print0 | sort -z)

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run. Nothing was changed."
  verb="Would create"
else
  verb="Created"
fi

echo "Target: $TARGET_ABS"
case "$MODE" in
  minimal) echo "Selection: --minimal ($MINIMAL_SET)" ;;
  only) echo "Selection: --only $(IFS=','; echo "${SELECT[*]}")" ;;
esac
echo
echo "$verb ${#created[@]} file(s):"
for f in "${created[@]+"${created[@]}"}"; do echo "  + $f"; done

if [ "${#skipped[@]}" -gt 0 ]; then
  echo
  echo "Skipped ${#skipped[@]} file(s) that already exist (not changed):"
  for f in "${skipped[@]}"; do echo "  = $f"; done
fi

if [ "${#gitignore_add[@]}" -gt 0 ]; then
  echo
  echo "Your .gitignore was left unchanged. Consider adding these lines to it:"
  for l in "${gitignore_add[@]}"; do echo "  $l"; done
fi

was_created() {
  local want="$1" f
  for f in "${created[@]+"${created[@]}"}"; do
    if [ "$f" = "$want" ]; then return 0; fi
  done
  return 1
}

# True if an adapters.txt has at least one enabled (non-comment) line.
adapters_enabled() {
  [ -f "$1" ] || return 1
  sed -e 's/\r$//' -e 's/#.*//' "$1" | grep -q '[^[:space:]]'
}

# Prune routing lines that point to files not copied, then sync adapters if
# any are enabled. Runs only when .pmkit/ was copied in this run.
if was_created ".pmkit/pmkit.py"; then
  PY=""
  for cand in python3 python "py -3"; do
    # Windows Store stubs for python/python3 exist on PATH but fail, so run
    # each candidate instead of only looking it up. $cand is split on purpose.
    # shellcheck disable=SC2086
    if $cand -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; then
      PY="$cand"
      break
    fi
  done
  PYSHOW="${PY:-python}"
  if [ "$DRY_RUN" -eq 1 ]; then
    ADAPTERS="$SRC/.pmkit/adapters.txt"
  else
    ADAPTERS="$TARGET_ABS/.pmkit/adapters.txt"
  fi
  run_sync=0
  if adapters_enabled "$ADAPTERS"; then run_sync=1; fi
  echo
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "Would run in $TARGET_ABS: $PYSHOW .pmkit/pmkit.py prune --dry-run, then prune after a yes"
    if [ "$run_sync" -eq 1 ]; then
      echo "Would run in $TARGET_ABS: $PYSHOW .pmkit/pmkit.py sync"
    else
      echo "Would not run sync: no adapter is enabled in .pmkit/adapters.txt."
    fi
  elif [ -z "$PY" ]; then
    echo "Python 3.8+ was not found, so nothing was pruned."
    echo "Install Python 3, then run this in $TARGET_ABS:"
    echo "  python .pmkit/pmkit.py prune"
    if [ "$run_sync" -eq 1 ]; then echo "  python .pmkit/pmkit.py sync"; fi
  else
    echo "Running in $TARGET_ABS: $PY .pmkit/pmkit.py prune --dry-run"
    prune_ok=1
    # shellcheck disable=SC2086
    preview="$(cd "$TARGET_ABS" && $PY .pmkit/pmkit.py prune --dry-run 2>&1)" || prune_ok=0
    printf '%s\n' "$preview"
    if [ "$prune_ok" -eq 0 ]; then
      echo "prune reported a problem (see above). Fix it, then run in $TARGET_ABS:"
      echo "  $PY .pmkit/pmkit.py prune"
    else
      case "$preview" in
        "nothing to prune"*) ;;
        *)
          do_prune=0
          if [ "$YES" -eq 1 ]; then
            do_prune=1
          elif [ -t 0 ]; then
            printf 'Remove these lines now? [y/N] '
            answer=""
            read -r answer || answer=""
            case "$answer" in y|Y|yes|YES|Yes) do_prune=1 ;; esac
          else
            echo "No terminal to ask and no --yes."
          fi
          if [ "$do_prune" -eq 1 ]; then
            echo "Running in $TARGET_ABS: $PY .pmkit/pmkit.py prune"
            # shellcheck disable=SC2086
            if ! (cd "$TARGET_ABS" && $PY .pmkit/pmkit.py prune); then
              echo "prune reported a problem (see above). Fix it, then run in $TARGET_ABS:"
              echo "  $PY .pmkit/pmkit.py prune"
            fi
          else
            echo "Nothing was pruned. To prune later, run in $TARGET_ABS:"
            echo "  $PY .pmkit/pmkit.py prune"
          fi
          ;;
      esac
    fi
    if [ "$run_sync" -eq 1 ]; then
      echo "Running in $TARGET_ABS: $PY .pmkit/pmkit.py sync"
      # shellcheck disable=SC2086
      if ! (cd "$TARGET_ABS" && $PY .pmkit/pmkit.py sync); then
        echo "sync reported a problem (see above). Fix it, then run in $TARGET_ABS:"
        echo "  $PY .pmkit/pmkit.py sync"
      fi
    else
      echo "No adapter is enabled in .pmkit/adapters.txt, so sync was not run."
    fi
  fi
fi

if was_created "README.md"; then
  README_HINT="README.md in this folder says what each file is for (delete it after reading)."
else
  README_HINT="What each file is for: $REPO_URL/blob/main/template/README.md"
fi

# A filled-in SETUP_DECISIONS.md means the interview already ran (this
# script was called after it), so do not tell the user to run it again.
interviewed=0
if [ -f "$TARGET_ABS/SETUP_DECISIONS.md" ] && ! grep -qF '<short name>' "$TARGET_ABS/SETUP_DECISIONS.md"; then
  interviewed=1
fi

echo
echo "Next steps:"
if [ "$interviewed" -eq 1 ]; then
  echo "  1. Files created. Fill PROJECT.md (and any other placeholders) with your agent."
  echo "  2. $README_HINT"
else
  echo "  1. Run the interview (Claude Code skill \"project-setup\", or paste a level's RUNFILE.md into any LLM)."
  echo "  2. Delete the files the interview did not justify. $README_HINT"
fi
if was_created "RULES.md"; then
  echo "     RULES.md holds the working rules. Edit it to fit. To trim it, delete whole sections:"
  echo "     \"## Code\" for a project with no code; \"## Agent\" and \"## Code\" if you only use a chat window."
fi
if was_created ".pmkit/pmkit.py" || [ -f "$TARGET_ABS/.pmkit/pmkit.py" ]; then
  echo "  3. If you keep .pmkit/: after deleting files run \"python .pmkit/pmkit.py prune\"."
  echo "     Enable an adapter in .pmkit/adapters.txt only for a tool that does not read AGENTS.md"
  echo "     (for Claude Code: \"CLAUDE.md import\"), then run \"python .pmkit/pmkit.py sync\"."
  echo "     Run \"python .pmkit/pmkit.py check\" to confirm the folder is consistent."
else
  echo "  3. Without .pmkit/, remove by hand any line ending in \"<!-- needs: X -->\" whose X you did not keep."
fi
