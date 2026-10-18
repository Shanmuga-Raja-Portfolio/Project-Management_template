#!/usr/bin/env python3
"""pmkit helper: keep a pmkit project folder consistent.

Python 3.8+, standard library only. Works on Windows and POSIX.

Commands (run from anywhere; the project root is the folder above .pmkit/):
  sync    write the adapter files enabled in .pmkit/adapters.txt (none by default)
  check   core files, AGENTS.md routes, adapters, needs-markers, links,
          placeholders, knowledge/ notes, "see D-###" pointers
          (.pmkit/ignore.txt lists files the pointer scan skips)
  prune   remove lines whose <!-- needs: PATH --> target does not exist
  log     append one entry to LOG.md
  decide  append the next D-### entry to DECISIONS.md

This script only checks and edits files. It cannot make an agent follow
the rules in AGENTS.md.
"""

import argparse
import datetime
import difflib
import fnmatch
import hashlib
import os
import posixpath
import re
import sys

try:  # Python 3
    from urllib.parse import unquote
except ImportError:  # pragma: no cover
    from urllib import unquote  # type: ignore

HEADER_MARK = "GENERATED from AGENTS.md by .pmkit/pmkit.py"
HEADER_FMT = ("<!-- GENERATED from AGENTS.md by .pmkit/pmkit.py (sha256:%s) "
              "-- edit AGENTS.md instead -->")
HASH_RE = re.compile(r"\(sha256:([0-9a-f]{12})\)")
MODES = ("copy", "import")
LOG_TYPES = ["CREATE", "UPDATE", "DECIDE", "TOOL-ADD", "TOOL-REMOVE",
             "REVIEW", "HANDOFF"]
RESERVED_KNOWLEDGE = {"index.md", "log.md"}
# Project files an adapter must never overwrite (compared case-insensitively).
PROTECTED_FILES = {"agents.md", "rules.md", "readme.md", "project.md", "status.md",
                   "decisions.md", "log.md", "setup_decisions.md", "sources.md",
                   ".gitignore"}
PROTECTED_DIRS = ("knowledge", ".pmkit", "stages")
# Files pmkit created. prune and check only read and edit these, plus the
# folders in SCAN_DIRS. README.md counts only when it is the kit's guide.
KIT_FILES = ("AGENTS.md", "RULES.md", "PROJECT.md", "STATUS.md", "DECISIONS.md",
             "LOG.md", "SETUP_DECISIONS.md", "SOURCES.md", "README.md")
KIT_README_TITLE = "# Project folder (guide to the pmkit files)"
SCAN_DIRS = ("knowledge", "stages")
# Files an agent setup must have (AGENTS.md is checked on its own).
CORE_FILES = ("RULES.md", "PROJECT.md", "STATUS.md")
# Folders the "see D-###" pointer scan skips.
SKIP_DIRS = {".git", ".hg", ".svn", ".pmkit", "node_modules", "__pycache__",
             ".venv", "venv", ".tox", ".mypy_cache", ".pytest_cache",
             ".ruff_cache", ".next", ".nuxt", "dist", "build", "target", "vendor"}
# Optional: one glob per line naming files the "see D-###" scan skips.
IGNORE_FILE = ".pmkit/ignore.txt"
# Existing decision-record folders that prune points the "Why is it like this?"
# routing row to when DECISIONS.md is gone.
DECISION_DIRS = ("docs/adr/", "doc/adr/", "docs/decisions/",
                 "docs/architecture/decisions/")
WHY_ROW = "why is it like this"
POINTER_RE = re.compile(r"\bsee\s+D-(\d+)\b", re.IGNORECASE)
DECISION_RE = re.compile(r"^##\s+D-(\d+)\b", re.MULTILINE)
MAX_SCAN_BYTES = 2 * 1024 * 1024

NEEDS_RE = re.compile(r"<!--\s*needs:\s*(.*?)\s*-->")
FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
HEADING_RE = re.compile(r"^ {0,3}(#{1,6})(\s|$)")
LIST_RE = re.compile(r"^(\s*)([-*+]|\d{1,9}[.)])\s")
LINK_RE = re.compile(r"!?\[[^\]]*\]\(\s*(<[^>]*>|[^)\s]+)(?:\s+(?:\"[^\"]*\"|'[^']*'))?\s*\)")
SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.\-]*:")
# Placeholders counted in every kit file (lower case).
PLACEHOLDERS = ("<fill in", "<short name>", "<yyyy-mm-dd>")
# In SETUP_DECISIONS.md every `<...>` in backticks is an unfilled template value.
SETUP_PLACEHOLDER_RE = re.compile(r"`<[^`>]*>`")
SYNC = "python .pmkit/pmkit.py sync"
PRUNE = "python .pmkit/pmkit.py prune"


# ---------- helpers ----------

def out(msg=""):
    """Print without crashing on consoles that cannot encode a character."""
    try:
        print(msg)
    except UnicodeEncodeError:
        enc = sys.stdout.encoding or "ascii"
        print(msg.encode(enc, "replace").decode(enc))


def err(msg):
    try:
        sys.stderr.write(msg + "\n")
    except UnicodeEncodeError:
        sys.stderr.write(msg.encode("ascii", "replace").decode("ascii") + "\n")


def default_root():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read_text(path):
    with open(path, "r", encoding="utf-8-sig") as f:
        return f.read()


def file_style(path):
    """Return (newline, has_bom) of an existing file."""
    with open(path, "rb") as f:
        raw = f.read()
    return ("\r\n" if b"\r\n" in raw else "\n"), raw.startswith(b"\xef\xbb\xbf")


def write_text(path, text, newline="\n", bom=False):
    parent = os.path.dirname(path)
    if parent and not os.path.isdir(parent):
        os.makedirs(parent)
    with open(path, "w", encoding="utf-8-sig" if bom else "utf-8",
              newline=newline) as f:
        f.write(text)


def append_text(path, text):
    """Append text on a fresh line, keeping the file's line endings."""
    existing = ""
    newline = "\n"
    if os.path.exists(path):
        existing = read_text(path)
        newline = file_style(path)[0]
    prefix = ""
    if existing and not existing.endswith("\n"):
        prefix = "\n"
    # newline= translates each "\n" written into the file's own line ending.
    with open(path, "a", encoding="utf-8", newline=newline) as f:
        f.write(norm(prefix + text))


def norm(text):
    return text.replace("\r\n", "\n").replace("\r", "\n")


def parse_date(value):
    try:
        return datetime.datetime.strptime(value, "%Y-%m-%d").date()
    except (TypeError, ValueError):
        return None


def today_str(args):
    if getattr(args, "date", None):
        if parse_date(args.date) is None:
            err("error: --date must be YYYY-MM-DD, got %r" % args.date)
            sys.exit(2)
        return args.date
    return datetime.date.today().isoformat()


def one_line(value):
    return " ".join((value or "").split())


def no_pipe(value):
    """LOG.md fields are separated by ' | '; keep '|' out of field values."""
    return one_line(value).replace("|", "/")


def short(line, width=72):
    line = line.strip()
    return line if len(line) <= width else line[:width - 3] + "..."


def inside_root(root, path):
    root_real = os.path.normcase(os.path.realpath(root))
    target = os.path.normcase(os.path.realpath(path))
    try:
        rel = os.path.relpath(target, root_real)
    except ValueError:  # different drive on Windows
        return False
    return not (rel == os.pardir or rel.startswith(os.pardir + os.sep)
                or os.path.isabs(rel))


def safe_rel(value):
    """Normalise a project-relative path; return None if it is unsafe."""
    rel = value.strip().replace("\\", "/")
    if not rel or rel.startswith("/") or re.match(r"^[A-Za-z]:", rel):
        return None
    if ".." in rel.split("/"):
        return None
    trailing = rel.endswith("/")
    rel = posixpath.normpath(rel)
    if rel in (".", "") or rel.startswith("../"):
        return None
    return rel + ("/" if trailing else "")


# ---------- adapters ----------

def protected_reason(root, rel):
    """Return why rel must not be an adapter, or None if it is fine."""
    target = os.path.join(root, *rel.split("/"))
    if not inside_root(root, target):
        return "resolves outside the project folder"
    inside = os.path.relpath(os.path.normcase(os.path.realpath(target)),
                             os.path.normcase(os.path.realpath(root)))
    parts = inside.replace(os.sep, "/").lower().split("/")
    if len(parts) == 1 and parts[0] in PROTECTED_FILES:
        if parts[0] == "agents.md":
            return "AGENTS.md is the source, not an adapter"
        return "a project file, not an adapter"
    if parts[0] in PROTECTED_DIRS:
        return "inside %s/, which pmkit never overwrites" % parts[0]
    if os.path.isdir(target):
        return "a folder, not a file"
    return None


def read_adapters(root):
    """Return ([(path, mode)], problems) from .pmkit/adapters.txt.

    Line format: '<path> [mode]', mode 'copy' (default) or 'import'.
    '#' starts a comment (whole line, or after whitespace).
    """
    path = os.path.join(root, ".pmkit", "adapters.txt")
    if not os.path.exists(path):
        return [], ["missing .pmkit/adapters.txt (no adapters will be generated)"]
    adapters, problems, seen = [], [], set()
    for raw in norm(read_text(path)).split("\n"):
        line = re.split(r"(?:^|\s)#", raw, maxsplit=1)[0].strip()
        if not line:
            continue
        fields = line.split()
        if len(fields) > 2:
            problems.append("adapters.txt: skipped %r (expected '<path> [copy|import]'; "
                            "paths with spaces are not supported)" % line)
            continue
        mode = fields[1].lower() if len(fields) == 2 else "copy"
        if mode not in MODES:
            problems.append("adapters.txt: skipped %r (mode must be copy or import)" % line)
            continue
        rel = safe_rel(fields[0])
        if rel is None or rel.endswith("/"):
            problems.append("adapters.txt: skipped unsafe path %r" % fields[0])
            continue
        reason = protected_reason(root, rel)
        if reason:
            problems.append("adapters.txt: skipped %r (%s)" % (fields[0], reason))
            continue
        if rel.lower() in seen:
            continue
        seen.add(rel.lower())
        adapters.append((rel, mode))
    return adapters, problems


def body_hash(body):
    return hashlib.sha256(norm(body).rstrip().encode("utf-8")).hexdigest()[:12]


def adapter_body(rel, mode, agents_text):
    if mode == "import":
        target = posixpath.relpath("AGENTS.md", posixpath.dirname(rel) or ".")
        return "@%s\n" % target
    return norm(agents_text).lstrip("\n")


def adapter_text(body):
    return HEADER_FMT % body_hash(body) + "\n\n" + body


def split_adapter(text):
    """Return (is_generated, recorded_hash_or_None, body) for an adapter file."""
    text = norm(text)
    first, _, rest = text.partition("\n")
    if HEADER_MARK not in first:
        return False, None, text
    m = HASH_RE.search(first)
    if rest.startswith("\n"):
        rest = rest[1:]
    return True, (m.group(1) if m else None), rest


def adapter_state(current, expected_body):
    """Classify an existing adapter file against what sync would write.

    Returns one of: 'same', 'stale' (generated, untouched, AGENTS.md changed),
    'edited' (generated, then edited by hand), 'foreign' (not generated by pmkit).
    """
    generated, recorded, body = split_adapter(current)
    if not generated:
        return "foreign"
    if recorded is None or body_hash(body) != recorded:
        return "edited"
    if body_hash(body) == body_hash(expected_body):
        return "same"
    return "stale"


def show_diff(rel, current, new, limit=400):
    lines = list(difflib.unified_diff(
        norm(current).split("\n"), norm(new).split("\n"),
        fromfile="%s (now)" % rel, tofile="%s (what sync would write)" % rel,
        lineterm=""))
    for line in lines[:limit]:
        out("    " + line)
    if len(lines) > limit:
        out("    ... (%d more diff lines)" % (len(lines) - limit))


def generated_files(root):
    """Paths (relative) of files whose first line carries the pmkit header.

    Looks at root-level files and .github/*.md, where adapters usually live.
    """
    found = []
    candidates = []
    for name in sorted(os.listdir(root)):
        candidates.append(name)
    gh = os.path.join(root, ".github")
    if os.path.isdir(gh):
        candidates.extend(".github/" + n for n in sorted(os.listdir(gh)))
    for rel in candidates:
        full = os.path.join(root, *rel.split("/"))
        if not os.path.isfile(full):
            continue
        try:
            with open(full, "r", encoding="utf-8-sig") as f:
                first = f.readline()
        except (UnicodeDecodeError, OSError):
            continue
        if HEADER_MARK in first:
            found.append(rel)
    return found


# ---------- sync ----------

def cmd_sync(args):
    root = args.root
    agents = os.path.join(root, "AGENTS.md")
    if not os.path.exists(agents):
        err("error: AGENTS.md not found in %s" % root)
        return 1
    try:
        agents_text = read_text(agents)
    except UnicodeDecodeError:
        err("error: AGENTS.md is not valid UTF-8; re-save it as UTF-8")
        return 1
    adapters, problems = read_adapters(root)
    for p in problems:
        err("warning: " + p)
    if not adapters:
        out("no adapters enabled in .pmkit/adapters.txt; nothing to do.")
        out("(Many agents read AGENTS.md directly. See the comments in that file.)")
        return 0
    status = 0
    for rel, mode in adapters:
        path = os.path.join(root, *rel.split("/"))
        body = adapter_body(rel, mode, agents_text)
        content = adapter_text(body)
        if not os.path.exists(path):
            if args.dry_run:
                out("would create %s (%s)" % (rel, mode))
            else:
                write_text(path, content)
                out("created    %s (%s)" % (rel, mode))
            continue
        try:
            current = norm(read_text(path))
        except UnicodeDecodeError:
            err("skipped    %s (not valid UTF-8; re-save it as UTF-8, "
                "or delete it and rerun sync)" % rel)
            status = 1
            continue
        state = adapter_state(current, body)
        if state == "same" and current == content:
            out("unchanged  %s" % rel)
            continue
        if state in ("edited", "foreign") and not args.force:
            if state == "foreign":
                out("refused    %s (it exists and was not written by pmkit)" % rel)
            else:
                out("refused    %s (it was edited by hand after pmkit wrote it)" % rel)
            out("    Lines starting with - are in the file now and would be lost:")
            show_diff(rel, current, content)
            if posixpath.basename(rel).lower() == "claude.md":
                out("    Claude Code's /init and # memory write to CLAUDE.md, so this "
                    "is expected.")
            out("    Merge anything you want to keep into AGENTS.md, then run: "
                "%s --force" % SYNC)
            status = 1
            continue
        verb = "overwrite" if state in ("edited", "foreign") else "update"
        if args.dry_run:
            out("would %s %s (%s)" % (verb, rel, mode))
            continue
        newline, bom = file_style(path)
        write_text(path, content, newline, bom)
        out("%s %s (%s)" % ("overwrote " if verb == "overwrite" else "updated   ",
                            rel, mode))
    return status


# ---------- markdown scanning (shared by prune and check) ----------

def is_kit_readme(path):
    """True if README.md is the kit's guide, not the project's own README."""
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            for line in f:
                if line.strip():
                    return line.strip() == KIT_README_TITLE
    except (UnicodeDecodeError, OSError):
        return False
    return False


def scan_files(root, skip):
    """Markdown files prune/check look at: the kit's own root files, knowledge/, stages/.

    Files the project had before pmkit (its own README.md, CONTRIBUTING.md, ...)
    are left alone. skip: lower-case relative paths to leave out (adapters).
    """
    found = []
    present = {}
    for name in os.listdir(root):
        if os.path.isfile(os.path.join(root, name)):
            present[name.lower()] = name
    for kit_name in KIT_FILES:
        name = present.get(kit_name.lower())
        if not name:
            continue
        if kit_name == "README.md" and not is_kit_readme(os.path.join(root, name)):
            continue
        found.append(name)
    for d in SCAN_DIRS:
        base = os.path.join(root, d)
        if not os.path.isdir(base):
            continue
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = sorted(x for x in dirnames if not x.startswith("."))
            for name in sorted(filenames):
                if name.lower().endswith(".md"):
                    found.append(os.path.relpath(os.path.join(dirpath, name), root)
                                 .replace(os.sep, "/"))
    result = []
    for rel in found:
        if rel.lower() in skip:
            continue
        full = os.path.join(root, *rel.split("/"))
        if not inside_root(root, full):
            continue
        try:
            with open(full, "r", encoding="utf-8-sig") as f:
                first = f.readline()
        except UnicodeDecodeError:
            first = ""
        if HEADER_MARK in first:  # a generated adapter; sync owns it
            continue
        result.append(rel)
    return result


def classify_lines(lines):
    """Yield (index, kind) for each line: 'fence', 'code', 'comment' or 'text'."""
    fence = None
    in_comment = False
    kinds = []
    for line in lines:
        if fence:
            m = FENCE_RE.match(line)
            if m and m.group(1)[0] == fence[0] and len(m.group(1)) >= len(fence) \
                    and not line.strip()[len(m.group(1)):].strip():
                fence = None
            kinds.append("fence" if fence is None else "code")
            continue
        if in_comment:
            kinds.append("comment")
            if "-->" in line:
                in_comment = False
            continue
        m = FENCE_RE.match(line)
        if m:
            fence = m.group(1)
            kinds.append("fence")
            continue
        stripped = re.sub(r"<!--.*?-->", "", line)
        if "<!--" in stripped:
            in_comment = True
        kinds.append("text")
    return kinds


def needs_targets(line):
    """Targets named by needs-markers on a line. '(...)' entries are notes only."""
    targets = []
    line = re.sub(r"(`+)(.+?)\1", "", line)  # markers quoted in inline code are text
    for group in NEEDS_RE.findall(line):
        for item in group.split(","):
            item = item.strip()
            if item and not item.startswith("("):
                targets.append(item)
    return targets


def target_missing(root, target):
    """True if a needs target is absent, None if the target is unusable."""
    rel = safe_rel(target)
    if rel is None:
        return None
    full = os.path.join(root, *rel.rstrip("/").split("/"))
    if rel.endswith("/"):
        return not os.path.isdir(full)
    return not os.path.exists(full)


def missing_needs(root, line):
    missing, bad = [], []
    for t in needs_targets(line):
        state = target_missing(root, t)
        if state is None:
            bad.append(t)
        elif state:
            missing.append(t)
    return missing, bad


# ---------- prune ----------

ORDERED_RE = re.compile(r"^(\s*)(\d{1,9})([.)])(\s.*)$")


def renumber_lists(lines, kinds, removed):
    """New text for kept ordered-list items in lists that lost an item.

    A list is a run of ordered items at the same indent, with more-indented
    continuation lines between them; a blank line or anything else ends it.
    Numbering restarts at the list's original first number. Returns {index: text}.
    """
    changes = {}
    i, n = 0, len(lines)
    while i < n:
        m = ORDERED_RE.match(lines[i]) if kinds[i] == "text" else None
        if not m:
            i += 1
            continue
        indent = len(m.group(1).expandtabs(4))
        items = [i]
        j = i + 1
        while j < n and lines[j].strip() and kinds[j] == "text":
            m2 = ORDERED_RE.match(lines[j])
            lead = len(lines[j].expandtabs(4)) - len(lines[j].expandtabs(4).lstrip())
            if m2 and len(m2.group(1).expandtabs(4)) == indent:
                items.append(j)
            elif lead <= indent:
                break
            j += 1
        if any(k in removed for k in items):
            number = int(m.group(2))
            for k in items:
                if k in removed:
                    continue
                mk = ORDERED_RE.match(lines[k])
                new = "%s%d%s%s" % (mk.group(1), number, mk.group(3), mk.group(4))
                if new != lines[k]:
                    changes[k] = new
                number += 1
        i = j
    return changes


def decision_dir(root):
    """The project's existing decision-record folder (e.g. docs/adr/), or None."""
    for rel in DECISION_DIRS:
        if os.path.isdir(os.path.join(root, *rel.rstrip("/").split("/"))):
            return rel
    return None


def repoint_why_row(root, line, missing):
    """New text for the routing row "Why is it like this?" when DECISIONS.md is
    gone but the project keeps its decisions in a folder such as docs/adr/.
    Returns None when the row should be pruned as usual."""
    if [m.lower() for m in missing] != ["decisions.md"]:
        return None
    if not line.strip().startswith("|") or WHY_ROW not in line.lower():
        return None
    folder = decision_dir(root)
    if folder is None:
        return None
    cells = line.strip().strip("|").split("|")
    if len(cells) < 2:
        return None
    indent = line[:len(line) - len(line.lstrip())]
    cells[1] = (" `%s` (the project's existing decision records) "
                "<!-- needs: %s --> " % (folder, folder))
    return indent + "|" + "|".join(cells) + "|"


def prune_lines(root, lines):
    """Return (kept_lines, removals, renumbered, repoints).

    A removal is (line_no, kind, text, count, targets). renumbered counts the
    ordered-list items whose number changed because an item above was removed.
    A repoint is (line_no, new_text): the "Why is it like this?" routing row,
    pointed at an existing decision folder instead of being removed.
    """
    kinds = classify_lines(lines)
    removals = []
    repoints = []
    removed = set()
    i, n = 0, len(lines)
    last_kept = None
    while i < n:
        line = lines[i]
        if kinds[i] != "text" or not needs_targets(line):
            last_kept = line
            i += 1
            continue
        missing, _bad = missing_needs(root, line)
        if not missing:
            last_kept = line
            i += 1
            continue
        new = repoint_why_row(root, line, missing)
        if new is not None:
            lines = lines[:i] + [new] + lines[i + 1:]
            repoints.append((i + 1, new))
            last_kept = new
            i += 1
            continue
        j = i + 1
        h = HEADING_RE.match(line)
        li = LIST_RE.match(line)
        if h:
            level = len(h.group(1))
            while j < n:
                h2 = HEADING_RE.match(lines[j])
                if kinds[j] == "text" and h2 and len(h2.group(1)) <= level:
                    break
                j += 1
            kind = "section"
        elif li:
            indent = len(li.group(1).expandtabs(4))
            while j < n and lines[j].strip() and kinds[j] == "text":
                lead = len(lines[j]) - len(lines[j].lstrip())
                if lead <= indent:
                    break
                j += 1
            kind = "list item"
        else:
            kind = "line"
        removals.append((i + 1, kind, line, j - i, missing))
        # Do not leave two blank lines where the removed block was.
        if (last_kept is None or last_kept.strip() == "") and j < n \
                and lines[j].strip() == "":
            j += 1
        removed.update(range(i, j))
        i = j
    changes = renumber_lists(lines, kinds, removed)
    keep = [changes.get(k, lines[k]) for k in range(n) if k not in removed]
    return keep, removals, len(changes), repoints


def cmd_prune(args):
    root = args.root
    adapters, problems = read_adapters(root)
    for p in problems:
        if not p.startswith("missing .pmkit/adapters.txt"):
            err("warning: " + p)
    skip = set(rel.lower() for rel, _ in adapters)
    total = 0
    changed = 0
    agents_changed = False
    for rel in scan_files(root, skip):
        full = os.path.join(root, *rel.split("/"))
        try:
            text = norm(read_text(full))
        except UnicodeDecodeError:
            err("skipped    %s (not valid UTF-8)" % rel)
            continue
        lines = text.split("\n")
        keep, removals, renumbered, repoints = prune_lines(root, lines)
        if not removals and not repoints:
            continue
        for line_no, new in repoints:
            out("%s %s:%d (DECISIONS.md is gone; the project keeps decisions in "
                "a folder): %s" % ("would repoint" if args.dry_run else "repointed  ",
                                   rel, line_no, short(new)))
        for line_no, kind, line, count, missing in removals:
            what = kind if count == 1 else "%s, %d lines" % (kind, count)
            out("%s %s:%d (%s; needs %s): %s"
                % ("would remove" if args.dry_run else "removed   ", rel, line_no,
                   what, ", ".join(missing), short(line)))
        if renumbered:
            out("%s %s: %d numbered list item(s)"
                % ("would renumber" if args.dry_run else "renumbered", rel, renumbered))
        total += len(removals)
        changed += len(repoints)
        if not args.dry_run:
            newline, bom = file_style(full)
            write_text(full, "\n".join(keep), newline, bom)
            if rel.lower() == "agents.md":
                agents_changed = True
    extra = " and %d row(s) repointed" % changed if changed else ""
    if total == 0 and changed == 0:
        out("nothing to prune: every needs-marker target exists.")
    elif args.dry_run:
        out("dry run: %d block(s) would be removed%s. Nothing was written."
            % (total, extra.replace("repointed", "would be repointed")))
    else:
        out("pruned %d block(s)%s." % (total, extra))
        if agents_changed and adapters:
            out("AGENTS.md changed. Now run: %s" % SYNC)
    return 0


# ---------- check ----------

def frontmatter(text):
    """Return the frontmatter block as a string, or None if absent/unclosed."""
    lines = norm(text).split("\n")
    if not lines or lines[0].strip() != "---":
        return None
    for i in range(1, len(lines)):
        if lines[i].strip() in ("---", "..."):
            return "\n".join(lines[1:i])
    return None


def top_key(block, key):
    """Value of a top-level 'key: value' line (simple YAML), or None."""
    m = re.search(r"^%s[ \t]*:(.*)$" % re.escape(key), block, re.MULTILINE)
    if not m:
        return None
    value = m.group(1).split(" #", 1)[0].strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        value = value[1:-1].strip()
    return value


def key_section(block, key):
    """For a top-level key, return (inline value, indented child lines).

    Returns None if the key is absent. Simple YAML only: enough for the
    fields this kit writes, not a full parser.
    """
    lines = block.split("\n")
    for i, line in enumerate(lines):
        m = re.match(r"^%s[ \t]*:(.*)$" % re.escape(key), line)
        if not m:
            continue
        inline = m.group(1).split(" #", 1)[0].strip()
        children = []
        for nxt in lines[i + 1:]:
            if nxt.strip() == "" or nxt.lstrip().startswith("#"):
                continue
            if not nxt[:1].isspace() and not nxt.startswith("-"):
                break
            children.append(nxt)
        return inline, children
    return None


def okf_conditional(block):
    """Messages for OKF conditionally required keys that are missing."""
    found = []
    gen = key_section(block, "generated")
    if gen is not None:
        inline, children = gen
        if inline.startswith("{"):
            has_by = re.search(r"[{,]\s*by\s*:\s*[^,}\s]", inline)
        else:
            has_by = any(re.match(r"^\s+by\s*:\s*\S", c) for c in children)
        if (inline or children) and not has_by:
            found.append("'generated' is present but has no 'by'")
    src = key_section(block, "sources")
    if src is not None:
        inline, children = src
        if inline.startswith("["):
            body = inline.strip("[] ")
            items = re.findall(r"\{[^}]*\}|[^,{}]+", body) if body else []
            bad = [it for it in items
                   if it.strip() and not re.search(r"\bresource\s*:", it)]
        else:
            items, current = [], None
            for c in children:
                m = re.match(r"^\s*-\s?(.*)$", c)
                if m:
                    current = [m.group(1)]
                    items.append(current)
                elif current is not None:
                    current.append(c)
            bad = [it for it in items
                   if not any(re.match(r"^\s*resource\s*:", x) for x in it)]
        if bad:
            found.append("%d 'sources' entr%s without 'resource'"
                         % (len(bad), "y" if len(bad) == 1 else "ies"))
    return found


def link_targets(line):
    """Relative link targets on a line (inline code and comments removed)."""
    clean = re.sub(r"<!--.*?-->", "", line)
    clean = re.sub(r"(`+)(.+?)\1", "", clean)
    found = []
    for raw in LINK_RE.findall(clean):
        target = raw.strip("<>").strip()
        if not target or target.startswith("#") or target.startswith("/") \
                or SCHEME_RE.match(target) or target.startswith("//"):
            continue
        target = re.split(r"[#?]", target, maxsplit=1)[0]
        if target:
            found.append(unquote(target))
    return found


def count_placeholders(rel, text):
    """Number of unfilled template values on one line (comments already removed)."""
    low = text.lower()
    count = sum(low.count(p) for p in PLACEHOLDERS)
    if rel.lower() == "setup_decisions.md":
        for m in SETUP_PLACEHOLDER_RE.findall(text):
            if not any(p in m.lower() for p in PLACEHOLDERS):
                count += 1
    return count


def check_markdown(root, skip, warnings, quiet_needs=()):
    """needs-markers, relative links and leftover placeholders.

    quiet_needs: (rel, line_no) pairs whose needs-warnings were already
    reported as errors (AGENTS.md routes).
    """
    for rel in scan_files(root, skip):
        full = os.path.join(root, *rel.split("/"))
        try:
            lines = norm(read_text(full)).split("\n")
        except UnicodeDecodeError:
            continue  # reported elsewhere when it matters
        kinds = classify_lines(lines)
        base = os.path.dirname(full)
        placeholders, first_ph = 0, None
        for idx, line in enumerate(lines):
            if kinds[idx] != "text":
                continue
            no = idx + 1
            missing = []
            if "needs:" in line and (rel, no) not in quiet_needs:
                missing, bad = missing_needs(root, line)
                for t in missing:
                    warnings.append("%s:%d needs %s, which does not exist "
                                    "(run: %s, or create it)" % (rel, no, t, PRUNE))
                for t in bad:
                    warnings.append("%s:%d needs-marker path %r is not a safe "
                                    "project-relative path" % (rel, no, t))
            for target in ([] if missing else link_targets(line)):
                path = os.path.normpath(os.path.join(base, *target.split("/")))
                if not os.path.exists(path):
                    warnings.append("%s:%d links to %s, which does not exist"
                                    % (rel, no, target))
            text = re.sub(r"<!--.*?-->", "", line)
            found = count_placeholders(rel, text)
            if found:
                placeholders += found
                if first_ph is None:
                    first_ph = no
        if placeholders:
            warnings.append("%s: %d unfilled placeholder(s) left (first on line %d)"
                            % (rel, placeholders, first_ph))


# ---------- core files, routes, decision pointers ----------

ROUTE_FILE_RE = re.compile(r"^[\w.<>/\-]*[\w\-]\.[A-Za-z]{1,5}$")
ROUTE_DIR_RE = re.compile(r"^[\w.<>/\-]+/$")
CODE_SPAN_RE = re.compile(r"(`+)(.+?)\1")


def route_paths(cell):
    """Paths a routing-table 'Read' cell routes to.

    Only a markdown link target or a whole inline-code span that looks like a
    path counts. A file name in plain prose ("never a DECISIONS.md") does not.
    """
    cell = re.sub(r"<!--.*?-->", "", cell)
    found = []
    for raw in LINK_RE.findall(CODE_SPAN_RE.sub("", cell)):
        target = raw.strip("<>").strip()
        if not target or target.startswith("#") or SCHEME_RE.match(target):
            continue
        found.append(unquote(re.split(r"[#?]", target, maxsplit=1)[0]))
    for _ticks, span in CODE_SPAN_RE.findall(cell):
        found.append(span.strip())
    paths = []
    for tok in found:
        tok = tok.replace("\\", "/")
        if tok.startswith("./"):
            tok = tok[2:]
        if not tok or "<" in tok or ">" in tok:
            continue  # an unfilled placeholder; counted as a placeholder instead
        if ROUTE_FILE_RE.match(tok) or (ROUTE_DIR_RE.match(tok) and len(tok) > 1):
            paths.append(tok)
    return paths


def route_prefix(path):
    """The fixed part of a route such as stages/NN-name/CONTEXT.md (stages/)."""
    parts = path.split("/")
    fixed = []
    for part in parts:
        if re.search(r"NN|\*", part):
            return "/".join(fixed) + "/" if fixed else None
        fixed.append(part)
    return path


def check_routes(root, agents_text, errors):
    """Errors for AGENTS.md routing-table rows that point to missing files.

    Returns the (rel, line_no) pairs reported, so needs-warnings are not doubled.
    """
    reported = set()
    lines = norm(agents_text).split("\n")
    kinds = classify_lines(lines)
    in_table = False
    for idx, line in enumerate(lines):
        if kinds[idx] != "text":
            in_table = False
            continue
        stripped = line.strip()
        if not stripped.startswith("|"):
            in_table = False
            continue
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        if not in_table:
            in_table = True
            continue  # header row
        if len(cells) < 2 or set(cells[0]) <= set("-: "):
            continue  # separator row
        for path in route_paths(cells[1]):
            target = route_prefix(path)
            if not target or target in CORE_FILES:
                continue  # core files get their own error
            state = target_missing(root, target)
            if state:
                errors.append("AGENTS.md:%d routes to %s, which does not exist "
                              "(create it, or run: %s)" % (idx + 1, path, PRUNE))
                reported.add(("AGENTS.md", idx + 1))
    return reported


def is_venv(path):
    return os.path.isfile(os.path.join(path, "pyvenv.cfg"))


def read_ignore(root):
    """Glob patterns from .pmkit/ignore.txt (one per line, '#' comments)."""
    path = os.path.join(root, *IGNORE_FILE.split("/"))
    if not os.path.isfile(path):
        return []
    try:
        text = read_text(path)
    except UnicodeDecodeError:
        return []
    patterns = []
    for raw in norm(text).split("\n"):
        line = raw.split("#", 1)[0].strip().replace("\\", "/")
        while line.startswith("./"):
            line = line[2:]
        line = line.lstrip("/")
        if line:
            patterns.append(line.lower())
    return patterns


def is_ignored(rel, patterns):
    """True if rel (a file, or a folder ending in '/') matches an ignore pattern.

    'legacy/' skips that folder; a pattern without '/' (such as '*.py') also
    matches the name in any folder; '*' matches across folders.
    """
    rel = rel.lower()
    name = posixpath.basename(rel.rstrip("/"))
    for pat in patterns:
        if pat.endswith("/"):
            if rel.startswith(pat) or fnmatch.fnmatchcase(rel, pat + "*"):
                return True
            continue
        if fnmatch.fnmatchcase(rel.rstrip("/"), pat):
            return True
        if "/" not in pat and fnmatch.fnmatchcase(name, pat):
            return True
    return False


def text_files(root, ignore=()):
    """Every text file under root, outside version control, dependencies,
    virtual environments, build output, .pmkit/ and the paths matched by
    .pmkit/ignore.txt. Yields relative paths."""
    for dirpath, dirnames, filenames in os.walk(root):
        base = os.path.relpath(dirpath, root).replace(os.sep, "/")
        base = "" if base == "." else base + "/"
        dirnames[:] = sorted(
            d for d in dirnames
            if d.lower() not in SKIP_DIRS and not is_venv(os.path.join(dirpath, d))
            and not is_ignored(base + d + "/", ignore))
        for name in sorted(filenames):
            if is_ignored(base + name, ignore):
                continue
            full = os.path.join(dirpath, name)
            try:
                if os.path.getsize(full) > MAX_SCAN_BYTES:
                    continue
                with open(full, "rb") as f:
                    raw = f.read()
            except OSError:
                continue
            if b"\0" in raw[:8192]:
                continue  # binary
            yield (os.path.relpath(full, root).replace(os.sep, "/"),
                   raw.decode("utf-8", "replace"))


def markdown_prose(lines):
    """Markdown lines with code blocks blanked and inline code removed."""
    kinds = classify_lines(lines)
    result = []
    for line, kind in zip(lines, kinds):
        if kind in ("code", "fence"):
            result.append("")
        else:
            result.append(re.sub(r"(`+)(.+?)\1", "", line))
    return result


def check_pointers(root, errors, warnings):
    """'see D-###' pointers (in code comments or prose) must name a real entry.

    With DECISIONS.md, a pointer to a missing entry is an error. Without it,
    the pointers probably belong to an older convention, so each file with
    pointers gets one warning. Files matched by .pmkit/ignore.txt are skipped.
    """
    path = os.path.join(root, "DECISIONS.md")
    known = None
    if os.path.exists(path):
        try:
            known = set(int(n) for n in DECISION_RE.findall(norm(read_text(path))))
        except UnicodeDecodeError:
            return  # reported by check_decision_ids
    for rel, text in text_files(root, read_ignore(root)):
        lines = norm(text).split("\n")
        if rel.lower().endswith(".md"):
            lines = markdown_prose(lines)
        orphans = []
        for idx, line in enumerate(lines):
            for m in POINTER_RE.finditer(line):
                did = "D-%s" % m.group(1)
                if known is None:
                    orphans.append((idx + 1, did))
                elif int(m.group(1)) not in known:
                    errors.append("%s:%d points to %s, which is not in DECISIONS.md "
                                  "(add the entry, fix the number, or list the file "
                                  "in %s)" % (rel, idx + 1, did, IGNORE_FILE))
        if orphans:
            where = ", ".join("%d (%s)" % o for o in orphans[:5])
            if len(orphans) > 5:
                where += ", and %d more" % (len(orphans) - 5)
            warnings.append("%s: %d 'see D-###' pointer(s), but this project has no "
                            "DECISIONS.md (line %s). If they belong to an older "
                            "convention, list the file in %s"
                            % (rel, len(orphans), where, IGNORE_FILE))


def check_decision_ids(root, errors):
    path = os.path.join(root, "DECISIONS.md")
    if not os.path.exists(path):
        return
    try:
        nums = [int(n) for n in DECISION_RE.findall(norm(read_text(path)))]
    except UnicodeDecodeError:
        errors.append("DECISIONS.md: not valid UTF-8; re-save it as UTF-8")
        return
    seen, dupes = set(), []
    for n in nums:
        if n in seen and n not in dupes:
            dupes.append(n)
        seen.add(n)
    for n in dupes:
        errors.append("DECISIONS.md: D-%03d is used for more than one entry; give the "
                      "later one the next free number" % n)


def check_claude_md(root, listed, warnings):
    """A hand-written CLAUDE.md that never mentions AGENTS.md hides the routing."""
    path = os.path.join(root, "CLAUDE.md")
    if "claude.md" in listed or not os.path.isfile(path):
        return
    try:
        text = read_text(path)
    except UnicodeDecodeError:
        return
    if HEADER_MARK in text.split("\n", 1)[0]:
        return
    if "AGENTS.md" not in text:
        warnings.append("CLAUDE.md does not mention AGENTS.md, so Claude Code may never "
                        "read AGENTS.md or RULES.md. Add the line @AGENTS.md to it, or "
                        "enable 'CLAUDE.md import' in .pmkit/adapters.txt")


def check_claude_adapter(rel, state, current, errors, warnings):
    """An enabled CLAUDE.md adapter with lines pmkit did not write.

    Claude Code itself writes to CLAUDE.md (/init, the # memory shortcut), so
    this is only a warning while the file still points to AGENTS.md.
    """
    how = ("exists but was not written by pmkit" if state == "foreign"
           else "was edited after pmkit wrote it")
    if "AGENTS.md" not in current:
        errors.append("%s %s and no longer mentions AGENTS.md, so Claude Code may "
                      "never read AGENTS.md or RULES.md. Merge its content into "
                      "AGENTS.md, then run: %s --force" % (rel, how, SYNC))
        return
    warnings.append("%s %s (Claude Code's /init and # memory write to it). Claude "
                    "Code still reads AGENTS.md through it. To keep the additions "
                    "for every agent, move them into AGENTS.md, then run: %s --force "
                    "(plain sync shows the diff)" % (rel, how, SYNC))


def cmd_check(args):
    root = args.root
    errors, warnings = [], []
    today = parse_date(today_str(args))

    # 0. chat-window set, core files, routes
    agents = os.path.join(root, "AGENTS.md")
    adapters, problems = read_adapters(root)
    agents_text = None
    quiet_needs = set()
    if not os.path.exists(agents):
        if not adapters:
            if all(os.path.exists(os.path.join(root, f))
                   for f in ("PROJECT.md", "STATUS.md")):
                out("chat-window set detected: PROJECT.md and STATUS.md, no AGENTS.md "
                    "and no adapters. check is meant for agent setups, so there is "
                    "nothing to check here. To move to an agent setup, add AGENTS.md "
                    "from the kit's template/ folder, and put back the Agent section "
                    "of RULES.md (and the Code section, for a code project) from the "
                    "kit's template/RULES.md.")
                return 0
            out("ERROR  AGENTS.md not found, and this is not a chat-window set either "
                "(that needs PROJECT.md and STATUS.md). Copy AGENTS.md, RULES.md, "
                "PROJECT.md and STATUS.md from the kit's template/ folder.")
            out("check failed: 1 error(s), 0 warning(s)")
            return 1
        errors.append("AGENTS.md not found, but adapters are enabled in "
                      ".pmkit/adapters.txt. Restore AGENTS.md; the adapters are "
                      "generated from it")
    else:
        try:
            agents_text = read_text(agents)
        except UnicodeDecodeError:
            errors.append("AGENTS.md: not valid UTF-8; re-save it as UTF-8")
    warnings.extend(problems)
    for name in CORE_FILES:
        if not os.path.exists(os.path.join(root, name)):
            errors.append("%s not found. An agent setup needs it; copy it from the "
                          "kit's template/ folder" % name)
    if agents_text is not None:
        quiet_needs = check_routes(root, agents_text, errors)
    check_decision_ids(root, errors)
    check_pointers(root, errors, warnings)

    # 1. adapters
    listed = set(rel.lower() for rel, _ in adapters)
    check_claude_md(root, listed, warnings)
    if agents_text is not None:
        for rel, mode in adapters:
            path = os.path.join(root, *rel.split("/"))
            if not os.path.exists(path):
                errors.append("%s missing (run: %s)" % (rel, SYNC))
                continue
            try:
                current = norm(read_text(path))
            except UnicodeDecodeError:
                errors.append("%s: not valid UTF-8; re-save it as UTF-8" % rel)
                continue
            body = adapter_body(rel, mode, agents_text)
            state = adapter_state(current, body)
            if state in ("foreign", "edited") \
                    and posixpath.basename(rel).lower() == "claude.md":
                check_claude_adapter(rel, state, current, errors, warnings)
            elif state == "foreign":
                errors.append("%s exists but was not written by pmkit. Merge its "
                              "content into AGENTS.md, then run: %s --force"
                              % (rel, SYNC))
            elif state == "edited":
                errors.append("%s was edited by hand after pmkit wrote it. Merge the "
                              "edit into AGENTS.md, then run: %s --force (plain sync "
                              "shows the diff)" % (rel, SYNC))
            elif state == "stale" or current != adapter_text(body):
                errors.append("%s is out of date with AGENTS.md (run: %s)" % (rel, SYNC))
    for rel in generated_files(root):
        if rel.lower() not in listed:
            warnings.append("%s was generated by pmkit but is not enabled in "
                            ".pmkit/adapters.txt (delete it, or enable it again)" % rel)

    # 2. needs-markers, links, placeholders
    check_markdown(root, listed, warnings, quiet_needs)

    # 3. knowledge frontmatter
    kdir = os.path.join(root, "knowledge")
    if os.path.isdir(kdir):
        index = os.path.join(kdir, "index.md")
        if os.path.exists(index):
            try:
                block = frontmatter(read_text(index))
            except UnicodeDecodeError:
                errors.append("knowledge/index.md: not valid UTF-8; re-save it as UTF-8")
                block = "okf_version: unknown"
            if block is None or not top_key(block, "okf_version"):
                warnings.append("knowledge/index.md has no okf_version in frontmatter")
        for dirpath, dirnames, filenames in os.walk(kdir):
            dirnames[:] = sorted(d for d in dirnames if not d.startswith("."))
            for name in sorted(filenames):
                if not name.lower().endswith(".md"):
                    continue
                if name.lower() in RESERVED_KNOWLEDGE:
                    continue
                full = os.path.join(dirpath, name)
                rel = os.path.relpath(full, root).replace(os.sep, "/")
                try:
                    block = frontmatter(read_text(full))
                except UnicodeDecodeError:
                    errors.append("%s: not valid UTF-8; re-save it as UTF-8" % rel)
                    continue
                if block is None:
                    errors.append("%s: no YAML frontmatter (needs at least 'type')" % rel)
                    continue
                if not top_key(block, "type"):
                    errors.append("%s: frontmatter has no non-empty 'type'" % rel)
                for msg in okf_conditional(block):
                    warnings.append("%s: %s (OKF v0.2 requires it)" % (rel, msg))
                stale = top_key(block, "stale_after")
                if stale:
                    d = parse_date(stale)
                    if d is None:
                        warnings.append("%s: stale_after %r is not YYYY-MM-DD" % (rel, stale))
                    elif d < today:
                        warnings.append("%s: stale since %s; re-check it" % (rel, stale))

    for w in warnings:
        out("WARN   " + w)
    for e in errors:
        out("ERROR  " + e)
    if errors:
        out("check failed: %d error(s), %d warning(s)" % (len(errors), len(warnings)))
        return 1
    out("check passed: 0 errors, %d warning(s)" % len(warnings))
    return 0


# ---------- log ----------

def log_line(date, kind, summary, files):
    line = "- %s | %s | %s" % (date, kind, no_pipe(summary))
    names = [no_pipe(f) for f in (files or "").split(",") if f.strip()]
    if names:
        line += " | files: %s" % ", ".join(names)
    return line + "\n"


def cmd_log(args):
    kind = args.type.upper()
    if kind not in LOG_TYPES:
        err("error: --type must be one of %s" % ", ".join(LOG_TYPES))
        return 2
    if not one_line(args.summary):
        err("error: --summary is empty")
        return 2
    path = os.path.join(args.root, "LOG.md")
    if not os.path.exists(path):
        err("error: LOG.md not found in %s. This project keeps no work log "
            "(for code in git, the git history covers it). To start one, copy "
            "LOG.md from the kit's template/ folder." % args.root)
        return 1
    line = log_line(today_str(args), kind, args.summary, args.files)
    append_text(path, line)
    out("appended to LOG.md: " + line.rstrip("\n"))
    return 0


# ---------- decide ----------

def cmd_decide(args):
    path = os.path.join(args.root, "DECISIONS.md")
    if not os.path.exists(path):
        err("error: DECISIONS.md not found in %s. To start one, copy DECISIONS.md "
            "from the kit's template/ folder." % args.root)
        return 1
    if not one_line(args.title):
        err("error: --title is empty")
        return 2
    text = read_text(path)
    nums = [int(n) for n in re.findall(r"^##\s+D-(\d+)\b", text, re.MULTILINE)]
    num = (max(nums) + 1) if nums else 1
    did = "D-%03d" % num
    date = today_str(args)
    entry = (
        "\n## %s (%s): %s\n\n"
        "- Decision: %s\n"
        "- Why: %s\n"
        "- Alternatives considered: %s\n"
        "- Revisit when: %s\n"
    ) % (did, date, one_line(args.title),
         one_line(args.decision) or one_line(args.title),
         one_line(args.why) or "<fill in>",
         one_line(args.alternatives) or "<fill in>",
         one_line(args.revisit) or "<fill in>")
    append_text(path, entry)
    out("appended %s to DECISIONS.md" % did)
    if not args.no_log:
        log_path = os.path.join(args.root, "LOG.md")
        if os.path.exists(log_path):
            append_text(log_path, log_line(date, "DECIDE", "%s %s" % (did, args.title),
                                           "DECISIONS.md"))
            out("appended DECIDE entry to LOG.md")
        else:
            out("no LOG.md in this project; no DECIDE line written")
    return 0


# ---------- main ----------

def build_parser():
    common = argparse.ArgumentParser(add_help=False)
    # --root works before or after the command. The sub-command copy has no
    # default, so it only replaces the top-level value when it is given.
    common.add_argument("--root", default=argparse.SUPPRESS,
                        help="project root (default: the folder above .pmkit/)")

    p = argparse.ArgumentParser(
        prog="pmkit.py",
        description="Keep a pmkit project folder consistent. Standard library only. "
                    "It only checks and edits files; it cannot make an agent "
                    "follow AGENTS.md.")
    p.add_argument("--root", default=default_root(),
                   help="project root (default: the folder above .pmkit/)")
    sub = p.add_subparsers(dest="command", metavar="command")

    s = sub.add_parser(
        "sync", parents=[common],
        help="write the adapter files enabled in .pmkit/adapters.txt",
        description="For each line '<path> [copy|import]' in .pmkit/adapters.txt "
                    "(none are enabled by default), write <path> with a GENERATED "
                    "header that records a hash of the content. 'copy' writes the "
                    "whole of AGENTS.md; 'import' writes only '@AGENTS.md' (for "
                    "tools such as Claude Code that support @path imports). sync "
                    "refuses to overwrite a file that pmkit did not write, or that "
                    "was edited by hand since, and prints a diff; merge the edit "
                    "into AGENTS.md, then rerun with --force.")
    s.add_argument("--dry-run", action="store_true", help="show what would change")
    s.add_argument("--force", action="store_true",
                   help="overwrite adapter files that were edited by hand or not "
                        "written by pmkit")
    s.set_defaults(func=cmd_sync)

    c = sub.add_parser(
        "check", parents=[common],
        help="check adapters, needs-markers, links, placeholders and knowledge/",
        description="Errors (exit 1): AGENTS.md, RULES.md, PROJECT.md or STATUS.md "
                    "missing; a row of the AGENTS.md routing table that names a "
                    "missing file (only a link or a path in backticks counts as a "
                    "route); a 'see D-###' pointer in any text file whose D-### is "
                    "not in DECISIONS.md; a D-### number used twice; an enabled "
                    "adapter missing, out of date, edited by hand or not written by "
                    "pmkit (for CLAUDE.md, only when it no longer mentions "
                    "AGENTS.md); a knowledge/*.md "
                    "file (other than index.md and log.md) without frontmatter or a "
                    "non-empty 'type'; a file that is not UTF-8. "
                    "Warnings: 'see D-###' pointers when there is no DECISIONS.md; "
                    "a CLAUDE.md adapter with lines pmkit did not write; "
                    "a <!-- needs: PATH --> marker whose PATH is missing "
                    "(run prune); a relative markdown link to a missing file; "
                    "unfilled placeholders ('<fill in', '<short name>', "
                    "'<YYYY-MM-DD>', and any `<...>` value in SETUP_DECISIONS.md); a "
                    "generated file no longer enabled in adapters.txt; a hand-written "
                    "CLAUDE.md that never mentions AGENTS.md; stale_after in the past; "
                    "bad dates; 'generated' without 'by'; 'sources' entries without "
                    "'resource'. Lints only the files pmkit created (AGENTS.md, "
                    "RULES.md, PROJECT.md, STATUS.md, DECISIONS.md, LOG.md, "
                    "SETUP_DECISIONS.md, the kit's README.md guide) and knowledge/ and "
                    "stages/; the project's own README, CONTRIBUTING and docs are not "
                    "linted. The D-### pointer scan skips .git, node_modules, virtual "
                    "environments, build output, .pmkit/ and every path matched by "
                    "a glob in .pmkit/ignore.txt (one per line; 'legacy/' skips a "
                    "folder, '*.py' matches in any folder). In a chat-window set "
                    "(PROJECT.md and STATUS.md, no AGENTS.md, no adapters) it says so "
                    "and exits 0.")
    c.add_argument("--date", help="treat this YYYY-MM-DD as today (for testing)")
    c.set_defaults(func=cmd_check)

    pr = sub.add_parser(
        "prune", parents=[common],
        help="remove lines that point to files this project dropped",
        description="Remove every line, table row or list item carrying a "
                    "<!-- needs: PATH --> marker whose PATH does not exist (PATH is "
                    "relative to the project root; a trailing / means a folder; "
                    "several paths may be separated by commas, and all must exist). "
                    "A marker on a heading removes the whole section. Markers like "
                    "<!-- needs: (optional) --> are notes and are never acted on. "
                    "A numbered list that loses an item is renumbered. If "
                    "DECISIONS.md is gone but the project has docs/adr/ (or "
                    "doc/adr/, docs/decisions/, docs/architecture/decisions/), the "
                    "AGENTS.md row for \"Why is it like this?\" is pointed there "
                    "instead of being removed. "
                    "Edits only the files pmkit created (see check --help) and "
                    "knowledge/ and stages/, skips code blocks and generated "
                    "adapters, and keeps each file's line endings. Run sync "
                    "afterwards if AGENTS.md changed.")
    pr.add_argument("--dry-run", action="store_true",
                    help="show what would be removed; write nothing")
    pr.set_defaults(func=cmd_prune)

    lg = sub.add_parser("log", parents=[common], help="append an entry to LOG.md",
                        description="Append one line to LOG.md: "
                                    "'- DATE | TYPE | summary | files: ...'. "
                                    "A '|' inside the summary or a file name "
                                    "is written as '/'.")
    lg.add_argument("--type", required=True, metavar="TYPE",
                    help="one of: " + ", ".join(LOG_TYPES))
    lg.add_argument("--summary", required=True, help="one-line summary")
    lg.add_argument("--files", default="", help="comma-separated list of files")
    lg.add_argument("--date", help="YYYY-MM-DD (default: today)")
    lg.set_defaults(func=cmd_log)

    d = sub.add_parser("decide", parents=[common],
                       help="append the next D-### entry to DECISIONS.md",
                       description="Append the next numbered decision to DECISIONS.md "
                                   "and, if LOG.md exists, a DECIDE line to LOG.md. "
                                   "Numbers are max+1 in this copy of the file, so two "
                                   "branches can pick the same number; renumber by "
                                   "hand when merging.")
    d.add_argument("--title", required=True, help="short decision title")
    d.add_argument("--decision", default="", help="full decision (default: the title)")
    d.add_argument("--why", default="", help="reason")
    d.add_argument("--alternatives", default="", help="alternatives considered")
    d.add_argument("--revisit", default="", help="trigger or date to revisit")
    d.add_argument("--date", help="YYYY-MM-DD (default: today)")
    d.add_argument("--no-log", action="store_true", help="do not add a LOG.md entry")
    d.set_defaults(func=cmd_decide)
    return p


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    if not getattr(args, "command", None):
        parser.print_help()
        return 2
    args.root = os.path.abspath(args.root)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
