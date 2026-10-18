#!/usr/bin/env python3
"""Generate the per-level RUNFILE.md prompts from the canonical sources.

A RUNFILE is a self-contained prompt. Anyone can paste it into any capable
LLM (Claude, ChatGPT, Gemini, a local model) and get the same interview the
Claude Code skill runs. Do not edit RUNFILEs by hand: edit the sources and
run this script again.

Usage:
    python scripts/build_runfiles.py           # write all three RUNFILEs
    python scripts/build_runfiles.py --check   # exit 1 if any RUNFILE is stale,
                                               # over its size budget, or breaks
                                               # the Level 1 content rules

Each RUNFILE carries only what its level needs:

- interview/MAPPING.md is split on its "## " sections. Each title must start
  with "All levels", "Level 1", "Level 2" or "Level 3" (an optional leading
  number such as "3. " is allowed). Level N gets "All levels" plus every
  "Level k" section with k <= N, in file order.
- interview/CONDUCT.md and interview/OUTPUTS.md sections (any heading depth)
  whose title starts with "Level k" or holds "(Level k" are dropped below
  level k. The SETUP_PLAN.md format is Level 3 only.
- interview/QUESTIONS.md is filtered on each question's "Levels:" line.
- Level 1 has no tool cards. Levels 2 and 3 get condensed tool cards (a fixed
  set of sections, plus a link to the full card). The method cards (ICM, OKF,
  Procedural Graphs) are a three-line note at every level: the starter files
  already apply them. The overlaps guide and the installers README are linked,
  not embedded.
- Template files are embedded in ~~~~ fences, so their headings are not read
  as RUNFILE sections, and introduced as file contents to create. RULES.md,
  AGENTS.md, PROJECT.md, STATUS.md, DECISIONS.md, LOG.md and .gitignore are
  embedded exactly as they are in template/, minus whole-line guidance HTML
  comments (needs-markers stay), so a RUNFILE user and a new-project script
  user get the same files. SETUP_DECISIONS.md is the short form from
  interview/OUTPUTS.md (moved there from the Output formats section, not
  repeated). knowledge/, stages/, .pmkit/ and README.md are short descriptions
  with links.
- Level 1 is linted: it must not name Level 2/3 tools or mention questions it
  does not ask.
- Every RUNFILE is linted for direction: a quoted section title followed by
  "below" or "above" must point the right way.

Size budgets (bytes / 4, roughly tokens): Level 1 7,500, Level 2 15,000,
Level 3 23,000. Over budget is an error.

Relative links in the sources are rewritten: a link to a file embedded in the
same RUNFILE becomes '"<section>" below' or '... above', whichever is true in
the built file; any other link becomes "kit repo: `path`" (the session rules
give the repo URL once), full-card links included. The build fails
if a relative .md link would remain.

Condensing (RUNFILE only; the sources keep everything): guidance comments in
templates, "Why it matters" bullets, bullets tagged for a higher level, output
examples and boilerplate pointers repeated in every card.

Python 3.8+, standard library only. Works on Windows and POSIX.
"""

import argparse
import posixpath
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REPO_URL = "https://github.com/Shanmuga-Raja-Portfolio/Project-Management_template"
INSTALLERS_README = "levels/2-starter-tools/installers/README.md"
LOCAL_MODELS_GUIDE = "guides/local-models.md"
CHAT_WINDOW_GUIDE = "guides/chat-window.md"

# bytes / 4, roughly tokens.
BUDGETS = {1: 7500, 2: 15000, 3: 23000}
# Context window to recommend per level (kept equal to guides/local-models.md).
CONTEXT_K = {1: 16, 2: 32, 3: 32}

DISCLAIMER = (
    "This kit recommends third-party tools. It does not own or vouch for them. "
    "Read each tool card and the upstream README before installing. Check what "
    "leaves your machine. Security testing tools (e.g. Strix) may only be used on "
    "systems you own or have written permission to test. No warranty (MIT)."
)

# Level 1 recommends no third-party tools, so it gets a short disclaimer that
# names none (the Level 1 lint forbids Level 2/3 tool names everywhere).
DISCLAIMER_L1 = (
    "Level 1 installs and recommends no third-party tools. Check what your AI "
    "service may see before you paste project content. No warranty (MIT)."
)

# Method cards (ICM, OKF, Procedural Graphs) are not embedded at any level:
# the starter files already apply them and nothing is installed. A short note
# ("Methods (built in)") links to them instead.
METHOD_CARDS = ["icm", "okf", "procedural-graphs"]
CARDS = {
    1: [],
    2: ["archify", "graphify", "open-code-review", "langextract"],
}
# workflow-graph is offered at Level 3 only.
CARDS[3] = CARDS[2] + ["workflow-graph", "strix"]

# Card sections kept in a condensed card (heading prefixes, lower case).
# "Checked: 2026-10-17" matches "checked".
CARD_SECTIONS = ("one-liner", "what it does not do", "use when", "skip when",
                 "install", "api keys", "local model route",
                 "privacy-safe settings", "conflicts/overlaps", "checked")

# Level 1 must not name these tools or ask about questions it does not ask.
L1_FORBIDDEN_TOOLS = ("graphify", "Open Code Review", "LangExtract", "Archify",
                      "Strix", "workflow-graph")

# Template files embedded in full. Everything else is described in a line or
# two with a link to the full file.
# knowledge/, stages/, .pmkit/ and README.md are described instead.
FULL_TEMPLATES = ("RULES.md", "AGENTS.md", "PROJECT.md", "STATUS.md",
                  "DECISIONS.md", "LOG.md", ".gitignore")
# Order of the files in "Template files" (others follow, sorted).
TEMPLATE_ORDER = ("RULES.md", "AGENTS.md", "PROJECT.md", "STATUS.md",
                  "DECISIONS.md", "LOG.md", "SETUP_DECISIONS.md", ".gitignore",
                  "README.md")

TEMPLATE_TITLE = "Template files"

# Placeholder for "below"/"above", resolved once the RUNFILE is assembled:
# DIR_OPEN + <title of a "## " section> + DIR_CLOSE.
DIR_OPEN, DIR_CLOSE = "", ""


def where(title):
    """'"<title>" below' or '... above', decided after assembly."""
    return '"' + title + '" ' + DIR_OPEN + title + DIR_CLOSE


def kit(rel):
    """Short reference to a file in the kit repo. The session rules say once
    where the repo is, so the full URL is not repeated every time."""
    return "kit repo: `" + rel + "`"


def rules_text(level):
    tool_rule = (
        "- Level 1 installs and names no tools. If a later need comes up, say that\n"
        "  Level 2 or 3 of the kit covers tools, and stop there.\n"
        if level == 1 else
        "- State tool facts only from the tool cards below; otherwise say "
        "\"unverified\".\n")
    return (
        "## Rules that apply for the whole session\n"
        "\n"
        "- The conduct rules below hold throughout. \"Recommend nothing\" is a\n"
        "  valid outcome.\n"
        "- If you can read and write the user's folder (agent mode), create files\n"
        "  directly, or run scripts/new-project with --only from the kit repo\n"
        "  (`new-project.sh --only <files> <folder>`, or `new-project.ps1 -Only`;\n"
        "  it never overwrites). Otherwise print each file in a fenced block.\n"
        + tool_rule +
        "- A quoted name followed by \"below\" or \"above\" is a section of this\n"
        "  RUNFILE in that direction. \"kit repo: `path`\" means a file in\n"
        "  " + REPO_URL + " (browse `/blob/main/<path>`).\n"
        "  If you cannot open it, do not claim to know what it says.\n")


START_CHECK = (
    "**Before starting, quote this file's first heading and its last heading. "
    "If you cannot see both, say the file was cut off.** The first heading is "
    "the RUNFILE title; the last one is \"Start now\".")

PREAMBLES = {
    1: """\
# RUNFILE: Level 1 "Starter"

{generated}

{start_check}

You are helping a person set up a project folder for working with an AI
assistant. This is Level 1 of the Project-Management_template kit ("pmkit").
Level 1 installs nothing. It only creates a few plain files.

> {disclaimer}

{size}

## What you will do

1. Run the interview (conduct rules and the {nq} Level 1 questions below).
2. Choose files with the mapping rules, starting from the smallest set.
   RULES.md is in every set. Browser chat window only: PROJECT.md, STATUS.md,
   RULES.md (General and Documentation sections only) and a short
   SETUP_DECISIONS.md (kit repo: `{chat_guide}`).
3. Show the proposal as a short list (files, reasons, what was left out).
   Do not print SETUP_DECISIONS.md yet. Wait for yes.
4. Draft PROJECT.md with the user in 2 or 3 follow-up prompts (the interview
   does not ask its goal, scope or done-when); leave unknowns as placeholders.
5. Then produce each file once, from "Template files" below, pruned.
6. If a trigger for later fits, name it and say Level 2 or 3 covers it.

{rules}""",
    2: """\
# RUNFILE: Level 2 "Starter + tools"

{generated}

{start_check}

You are helping a person set up a project folder for working with an AI
assistant, plus optional light tools. This is Level 2 of the
Project-Management_template kit ("pmkit").

> {disclaimer}

{size}

## What you will do

1. Run the interview (conduct rules and the {nq} Level 2 questions below).
2. Choose starter files with the mapping rules and, only where a trigger holds
   now, light tools: Archify, graphify code-only, Open Code Review delegation
   mode, LangExtract. The upkeep cap (Q07) limits tools too. Later needs go
   under "Add later" with a date or milestone. Service-layer tools (Strix)
   are Level 3 only; if the answers point to one, say so.
3. Show the proposal as a short list (each tool with its trigger and a revisit
   date, and the files; RULES.md is in every set). Wait for yes. Draft
   PROJECT.md with the user, then produce each file once from "Template
   files" below, pruned.
4. For each chosen tool, the user runs its installer from the kit repo
   (`git clone {repo_url}.git`, or the ZIP):
   `levels/2-starter-tools/installers/<tool>.sh` or `.ps1`, `--dry-run`
   (`-DryRun`) first. It prints the exact version; the user records it under
   "Installed tools". You do not run them and never ask for keys.

The model is the user's choice. Routine work can run on a local model
(Ollama, LM Studio); keep judgement-heavy work on a stronger one, unless the
data-sensitivity answer (Q08) rules out cloud services. The `/v1` suffix
differs per tool.

{rules}""",
    3: """\
# RUNFILE: Level 3 "Interview-led (power user)"

{generated}

{start_check}

You are helping an experienced person decide how to set up a project for
working with an AI assistant. This is Level 3 of the Project-Management_template
kit ("pmkit"). The main goal is to control bloat: recommend the least that works.

> {disclaimer}

{size}

## What you will do

1. Say in two sentences what Level 3 is: the full interview, then either a
   written plan only or a tailored scaffold, whichever the user prefers.
2. Ask Q17 first: written plan only, or plan plus scaffold. "Plan only" writes
   SETUP_PLAN.md and nothing else. "Plan plus scaffold" writes
   SETUP_DECISIONS.md plus the files, and no SETUP_PLAN.md.
3. Run the rest of the interview using the conduct rules and the Level 3
   questions.
4. Use the mapping rules and the overlap guide. Start with the Method layer
   (files only). Add a Tool only on a trigger that holds now; things needed
   only later (for example at a handoff) go under "Add later" with a date or
   milestone. Treat the Service layer (Strix, cloud backends of tools) as
   manual, guided steps with clear warnings about data, cost, telemetry and
   risk.
5. Strix may only be suggested if the user owns the target or has written
   permission to test it. Never suggest pointing it at production or at
   third-party systems.
6. If the user names a tool that is not in the catalog ("bring your own tool"),
   follow the bring-your-own-tool procedure below: fill the card template from
   what the user can show you, check overlaps with what is already chosen,
   warn about conflicts and unknowns, add the disclaimer, and let the user
   decide. Mark anything you could not check as "unverified".
7. Plan only: draft SETUP_PLAN.md (format in the outputs section): use these,
   here is why, here is when to add more later, here is what was declined.
   Plan plus scaffold: show the proposal as a short list (RULES.md is in
   every set), wait for yes, draft PROJECT.md with the user, then produce
   each file once from "Template files" below, SETUP_DECISIONS.md last. Keep the
   structure of the files you keep, but remove routing rows, rules and links
   that point to files you dropped (run pmkit prune if .pmkit is present).
8. Light tools are installed by the user with the installers in the kit repo
   at {repo_url} (`git clone {repo_url}.git`, then
   `levels/2-starter-tools/installers/`). They install the latest version
   unless given `--version <v>` (PowerShell: `-Version <v>`). Installer
   details: kit repo: `{installers}`. You do not run them.
9. Every tool decision gets a trigger and a revisit date. Tools that do not pay
   off get removed (log a TOOL-REMOVE entry if the project keeps LOG.md).

The model is the user's choice. Routine, mechanical work can run on a local
model (Ollama, LM Studio). Keep judgement-heavy work on a stronger model,
unless the data-sensitivity answer (Q08) rules out cloud services. Tools that
need tool calls or agent loops are unreliable on small local models.

{rules}""",
}

GENERATED_NOTE = (
    "<!-- GENERATED by scripts/build_runfiles.py. Edit the sources, not this "
    "file. -->"
)

SIZE_MARK = "@@RUNFILE_SIZE@@"

CLOSING = """\
---

## Start now

Do not summarise this RUNFILE. Quote its first heading and this one; if you
cannot see the first, say the file was cut off and stop. Then greet the user,
explain this level in two sentences, and ask the first question.
"""

Q_HEADING = re.compile(r"^###\s+(Q\d+)\s*[—–-]+\s*(.*?)\s*$")
HEADING = re.compile(r"^(#{1,6})\s")
LEVELS_LINE = re.compile(r"^\s*(?:[-*]\s*)?\**\s*Levels\s*\**\s*:\s*\**\s*(.*)$", re.I)
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
# [text](target) or ![alt](target), optional "title". No nested brackets.
LINK = re.compile(r'(!?)\[([^\]\n]*)\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)')
CODE_SPAN = re.compile(r"(`+)[^`].*?(?<!`)\1(?!`)")
ABSOLUTE = re.compile(r"^(?:[a-zA-Z][a-zA-Z0-9+.-]*:|//)")
NUMBERING = re.compile(r"^\d+[a-z]?[.)]\s+")
LEVEL_START = re.compile(r"^levels?[ -](\d)", re.I)
LEVEL_PAREN = re.compile(r"\(\s*levels?[ -](\d)", re.I)
QID = re.compile(r"\bQ(\d{2})\b")


FILE_LABEL = re.compile(r"^[\w./-]+\.md$")


class SourceError(Exception):
    pass


def read_source(rel):
    path = REPO / rel
    if not path.is_file():
        raise SourceError("missing source file: " + rel)
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        raise SourceError(rel + ": not valid UTF-8 text")
    return text.replace("\r\n", "\n").replace("\r", "\n")


def strip_frontmatter(text):
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end != -1:
            return text[end + 5:].lstrip("\n")
    return text


def iter_lines_with_fence(text):
    """Yield (line, inside_fence) so callers can leave code blocks alone."""
    fence = None
    for line in text.split("\n"):
        m = FENCE.match(line)
        if fence is None:
            if m:
                fence = m.group(1)
                yield line, True
                continue
            yield line, False
        else:
            if m and m.group(1)[0] == fence[0] and len(m.group(1)) >= len(fence) \
                    and line.strip() == m.group(1):
                fence = None
            yield line, True


def shift_headings(text, by=1):
    out = []
    for line, fenced in iter_lines_with_fence(text):
        if not fenced:
            m = HEADING.match(line)
            if m:
                level = min(6, len(m.group(1)) + by)
                line = "#" * level + line[len(m.group(1)):]
        out.append(line)
    return "\n".join(out)


def first_heading(text):
    for line, fenced in iter_lines_with_fence(text):
        if not fenced:
            m = HEADING.match(line)
            if m:
                return line[len(m.group(1)):].strip()
    return None


def headings(text):
    """Return [(depth, title)] for headings outside fences."""
    out = []
    for line, fenced in iter_lines_with_fence(text):
        if not fenced:
            m = HEADING.match(line)
            if m:
                out.append((len(m.group(1)), line[len(m.group(1)):].strip()))
    return out


def replace_section(text, heading_pred, new_body):
    """Replace (new_body is a str) or drop (new_body is None) every heading
    block whose heading text matches heading_pred, up to the next heading of
    the same or higher rank. Fence-aware. Returns (text, count)."""
    out = []
    skipping_level = None
    count = 0
    for line, fenced in iter_lines_with_fence(text):
        m = None if fenced else HEADING.match(line)
        if m:
            level = len(m.group(1))
            if skipping_level is not None and level <= skipping_level:
                skipping_level = None
            if skipping_level is None and heading_pred(line[level:].strip(), level):
                skipping_level = level
                count += 1
                if new_body is not None:
                    out.append(line)
                    out.append("")
                    out.append(new_body)
                    out.append("")
                continue
        if skipping_level is None:
            out.append(line)
    return "\n".join(out), count


def split_sections(text, depth=2):
    """Split on headings of exactly `depth` (outside fences).
    Returns (intro, [(title, block_text)])."""
    intro, sections = [], []
    cur = None
    for line, fenced in iter_lines_with_fence(text):
        m = None if fenced else HEADING.match(line)
        if m and len(m.group(1)) == depth:
            cur = [line[depth:].strip(), [line]]
            sections.append(cur)
            continue
        if cur is None:
            intro.append(line)
        else:
            cur[1].append(line)
    return "\n".join(intro), [(t, "\n".join(b)) for t, b in sections]


def heading_level_tag(title):
    """Minimum level a heading applies to, or None if it is not level-tagged.
    'All levels ...' -> 1, 'Level 2 ...' -> 2, '... (Level 2 and 3)' -> 2."""
    t = NUMBERING.sub("", title.strip().strip("*").strip())
    if t.lower().startswith("all levels"):
        return 1
    m = LEVEL_START.match(t) or LEVEL_PAREN.search(t)
    if m:
        return int(m.group(1))
    return None


def filter_mapping(text, level):
    """C6: keep 'All levels' and 'Level k' (k <= level) sections, in order."""
    intro, sections = split_sections(text, 2)
    if not sections:
        raise SourceError("interview/MAPPING.md: no '## ' sections found")
    bad = [t for t, _b in sections if heading_level_tag(t) is None
           or not re.match(r"^(all levels|level [123])",
                           NUMBERING.sub("", t).lower())]
    if bad:
        raise SourceError(
            "interview/MAPPING.md: every '## ' section title must start with "
            "'All levels', 'Level 1', 'Level 2' or 'Level 3'. Not tagged: "
            + "; ".join(bad[:6]))
    kept = [b for t, b in sections if heading_level_tag(t) <= level]
    out = intro.rstrip("\n") + "\n\n" + "\n\n".join(b.strip("\n") for b in kept)
    return out


def filter_level_tagged(text, level):
    """Drop any heading block (any depth) tagged for a level above `level`."""
    def pred(title, _depth):
        tag = heading_level_tag(title)
        return tag is not None and tag > level
    out, _n = replace_section(text, pred, None)
    return out


def _mask_code_spans(line):
    """Replace code spans with placeholders so a link whose label holds a code
    span (e.g. [`path/`](../path/README.md)) still matches LINK, while links
    written inside a code span stay untouched. Returns (masked, restore)."""
    spans = []

    def mask(m):
        spans.append(m.group(0))
        return "%d" % (len(spans) - 1)

    masked = CODE_SPAN.sub(mask, line)

    def restore(text):
        return re.sub("(\\d+)", lambda m: spans[int(m.group(1))], text)

    return masked, restore


def _repo_url_for(rel):
    path = REPO / rel
    kind = "tree" if path.is_dir() else "blob"
    return REPO_URL + "/" + kind + "/main/" + rel.rstrip("/")


def rewrite_links(text, src_rel, embedded, warnings):
    """Rewrite relative markdown links outside code so a pasted RUNFILE never
    points at a file it does not have.

    embedded maps repo-relative paths to (label, title of the "## " section
    that holds them). Such links become '<label> below' (or above, resolved
    after assembly), keeping the link text only when it is not a bare file
    name. Other
    repo paths become absolute GitHub links. Paths that do not exist in the
    repo become plain text (and a warning).
    """
    base = posixpath.dirname(src_rel)

    def repl(m):
        bang, label, target = m.group(1), m.group(2), m.group(3)
        if ABSOLUTE.match(target):
            return m.group(0)
        if target.startswith("#"):
            return label
        path, _, anchor = target.partition("#")
        rel = posixpath.normpath(posixpath.join(base, path))
        if rel == "." or rel.startswith("../"):
            warnings.add(src_rel + ": link points outside the repo: " + target)
            return label
        hit = embedded.get(rel) or embedded.get(rel + "/")
        if hit:
            text, anchor = hit
            ref = text + " " + DIR_OPEN + anchor + DIR_CLOSE
            if FILE_LABEL.match(label.strip("`")):
                return ref
            return label + " (" + ref + ")"
        if not (REPO / rel).exists():
            warnings.add(src_rel + ": link target not found: " + target)
            return label
        if bang:
            return bang + "[" + label + "](" + _repo_url_for(rel) + ")"
        ref = rel.rstrip("/") + ("/" if (REPO / rel).is_dir() else "") \
            + ("#" + anchor if anchor else "")
        if FILE_LABEL.match(label.strip("`")) or label.startswith("../") \
                or label.strip("`").rstrip("/") == rel.rstrip("/"):
            return "`" + ref + "` (kit repo)"
        return label + " (" + kit(ref) + ")"

    out = []
    for line, fenced in iter_lines_with_fence(text):
        if not fenced and "](" in line:
            masked, restore = _mask_code_spans(line)
            line = restore(LINK.sub(repl, masked))
        out.append(line)
    return "\n".join(out)


def find_relative_links(text):
    found = []
    for line, fenced in iter_lines_with_fence(text):
        if fenced or "](" not in line:
            continue
        masked, restore = _mask_code_spans(line)
        for m in LINK.finditer(masked):
            if not ABSOLUTE.match(m.group(3)):
                found.append(restore(m.group(0)))
    return found


def filter_questions(text, level_tag):
    """Keep only the ### Qnn blocks whose Levels line includes level_tag.

    Non-question headings (## groups) are kept only if at least one question
    under them is kept. Text before the first heading is kept.
    Returns (text, kept question ids).
    """
    blocks = []  # list of dicts: kind, level, lines, qid, levels
    current = {"kind": "intro", "level": 0, "lines": [], "qid": None, "levels": None}
    for line, fenced in iter_lines_with_fence(text):
        if not fenced:
            qm = Q_HEADING.match(line)
            hm = HEADING.match(line)
            if qm or hm:
                blocks.append(current)
                if qm:
                    current = {"kind": "q", "level": 3, "lines": [line],
                               "qid": qm.group(1), "levels": None}
                else:
                    current = {"kind": "h", "level": len(hm.group(1)),
                               "lines": [line], "qid": None, "levels": None}
                continue
            if current["kind"] == "q" and current["levels"] is None:
                lm = LEVELS_LINE.match(line)
                if lm:
                    tags = set(re.findall(r"L[123]", lm.group(1).upper()))
                    current["levels"] = tags
        current["lines"].append(line)
    blocks.append(current)

    questions = [b for b in blocks if b["kind"] == "q"]
    if not questions:
        raise SourceError(
            "interview/QUESTIONS.md: no question headings found. Expected "
            "'### Qnn — title' headings.")
    seen = set()
    for b in questions:
        if b["levels"] is None:
            raise SourceError(
                "interview/QUESTIONS.md: " + b["qid"] + " has no 'Levels: L1, L2, L3' line.")
        if not b["levels"]:
            raise SourceError(
                "interview/QUESTIONS.md: " + b["qid"] + " Levels line names no level (L1/L2/L3).")
        if b["qid"] in seen:
            raise SourceError("interview/QUESTIONS.md: duplicate id " + b["qid"])
        seen.add(b["qid"])

    keep = [False] * len(blocks)
    for i, b in enumerate(blocks):
        if b["kind"] == "intro":
            keep[i] = True
        elif b["kind"] == "q":
            keep[i] = level_tag in b["levels"]
    for i, b in enumerate(blocks):
        if b["kind"] != "h":
            continue
        for j in range(i + 1, len(blocks)):
            nb = blocks[j]
            if nb["kind"] == "h" and nb["level"] <= b["level"]:
                break
            if nb["kind"] == "q" and keep[j]:
                keep[i] = True
                break
        if b["level"] == 1:
            keep[i] = True
        elif not any(x["kind"] == "q" for x in blocks[i + 1:]):
            keep[i] = True

    qids = [b["qid"] for i, b in enumerate(blocks) if b["kind"] == "q" and keep[i]]
    if not qids:
        raise SourceError("interview/QUESTIONS.md: no questions tagged " + level_tag)
    out = []
    for i, b in enumerate(blocks):
        if keep[i]:
            out.extend(b["lines"])
    return "\n".join(out), qids


def drop_paragraphs(text, prefixes):
    """Drop maintainer-only paragraphs (outside fences) that start with one of
    `prefixes`, up to the next blank line."""
    out, skipping = [], False
    for line, fenced in iter_lines_with_fence(text):
        if not fenced and not skipping and line.startswith(prefixes):
            skipping = True
        if skipping:
            if line.strip() == "":
                skipping = False
            else:
                continue
        out.append(line)
    return "\n".join(out)


BULLET_LEVEL = re.compile(r"^\s*- \*\*[^*]*\(Levels? (\d)")


def strip_comments(text):
    """Drop HTML comments outside fences that are not needs-markers (single or
    multi-line). Inline needs-markers on content lines are kept."""
    out, in_comment = [], False
    for line, fenced in iter_lines_with_fence(text):
        if fenced:
            out.append(line)
            continue
        if in_comment:
            if "-->" in line:
                in_comment = False
            continue
        st = line.strip()
        if st.startswith("<!--") and "needs:" not in st:
            if "-->" not in st:
                in_comment = True
            continue
        out.append(line)
    return "\n".join(out)


def level_bullets(text, level, drop_labels=()):
    """Drop '- **Label (Level k ...)**' bullets with k > level, and bullets
    whose bold label starts with one of drop_labels. RUNFILE-only condensing:
    the source files keep them."""
    out = []
    for line, fenced in iter_lines_with_fence(text):
        if not fenced:
            m = BULLET_LEVEL.match(line)
            if m and int(m.group(1)) > level:
                continue
            if any(line.lstrip().startswith("- **" + l) for l in drop_labels):
                continue
        out.append(line)
    return "\n".join(out)


def fence_for(content):
    runs = [len(m) for m in re.findall(r"~{3,}", content)]
    return "~" * max(4, (max(runs) + 1) if runs else 4)


def template_files():
    root = REPO / "template"
    if not root.is_dir():
        raise SourceError("missing source directory: template/")
    files = []
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(root).as_posix()
        if "__pycache__" in rel.split("/") or rel.endswith(".pyc"):
            continue
        files.append((rel, p))
    if not files:
        raise SourceError("template/ is empty")
    for need in FULL_TEMPLATES:
        if need not in dict(files):
            raise SourceError("missing template file: template/" + need)

    def order(item):
        rel = item[0]
        if rel in TEMPLATE_ORDER:
            return (0, TEMPLATE_ORDER.index(rel), rel)
        return (1, 0, rel)
    return sorted(files, key=order)


def read_template(rel, p):
    try:
        return p.read_text(encoding="utf-8").replace("\r\n", "\n").replace("\r", "\n")
    except UnicodeDecodeError:
        raise SourceError("template/" + rel + " is not UTF-8 text")


def condense(content):
    """Trim trailing spaces and runs of blank lines. Keeps every comment,
    because '<!-- needs: ... -->' markers drive pruning. Guidance comments
    (whole-line comments without a needs-marker) are dropped."""
    content = strip_comments(content)
    lines = [l.rstrip() for l in content.split("\n")]
    out = []
    for l in lines:
        if l == "" and out and out[-1] == "":
            continue
        out.append(l)
    return "\n".join(out).strip("\n")


def template_url(rel):
    return kit("template/" + rel)


def pmkit_note(files):
    rels = [r for r, _p in files if r.startswith(".pmkit/")]
    py = dict(files).get(".pmkit/pmkit.py")
    size = ""
    if py is not None:
        lines = max(50, int(round(py.read_text(encoding="utf-8").count("\n") / 50.0)) * 50)
        size = " (`pmkit.py`, about " + str(lines) + " lines, Python 3.8+, standard library only)"
    return (
        "Optional helper" + size + ": " + ", ".join("`" + r + "`" for r in rels)
        + ". Do not write them from memory; the user downloads them ("
        + kit("template/.pmkit/") + "). Commands: `prune`, `sync` (only "
        "adapters enabled in `adapters.txt`; none by default), `check`, `log`, "
        "`decide`. Without it, prune by hand; for Claude Code a one-line "
        "`CLAUDE.md` holding `@AGENTS.md` is enough.")


def setup_decisions_note(level, short_form):
    if short_form is None:
        form = ("the short form" if level == 1 else
                "the short form, or the full form when more than the minimal "
                "set was chosen,")
        return "Write it in " + form + " in " + where("Output formats") + "."
    lines = ["Short form (5 to 10 lines). Write the answers in words."]
    if level > 1:
        lines.append("When more than the minimal set was chosen, use the full "
                     "form in " + where("Output formats") + " instead.")
    return " ".join(lines)


def move_short_form(outputs):
    """Take the short-form SETUP_DECISIONS.md block out of OUTPUTS so it is
    embedded once, as the template file. Returns (outputs, block or None)."""
    out, block, grab, done = [], [], False, False
    in_short = False
    for line, fenced in iter_lines_with_fence(outputs):
        m = None if fenced else HEADING.match(line)
        if m:
            t = line[len(m.group(1)):].strip().lower()
            in_short = "short form" in t and "setup_decisions" in t
        if not done and in_short and FENCE.match(line):
            if not grab:
                grab = True
                out.append("The template is file `SETUP_DECISIONS.md` in "
                           + where(TEMPLATE_TITLE) + ".")
                continue
            if line.strip() == FENCE.match(line).group(1) and block:
                grab, done = False, True
                continue
        if grab:
            block.append(line)
            continue
        out.append(line)
    if not done:
        return outputs, None
    return "\n".join(out), "\n".join(block).strip("\n")


def readme_note():
    return ("Optional guide to the starter files, read once and deleted. Not "
            "reproduced: " + template_url("README.md") + ".")


def short_description(prefix, rels):
    """Summary of knowledge/ or stages/ instead of their full templates.
    `rels` (the template files) are listed in the kit repo, not here."""
    _ = rels
    if prefix == "knowledge/":
        body = (
            "Only when the mapping keeps it. Notes in OKF v0.2 format. "
            "`index.md`: frontmatter `okf_version: \"0.2\"` and `title`, then "
            "a table (Concept, Type, Status, Description). `log.md`: append-only "
            "changes. One file per concept; frontmatter `type` required, plus "
            "optional `sources`, `generated: {by, at}`, `verified: []`. Only a "
            "person adds to `verified`.")
    else:
        body = (
            "Only when the mapping keeps it. One folder per "
            "stage, `NN-short-name/`, with a `CONTEXT.md`: Inputs, Process, "
            "Outputs, Handoff (Condition, Guidance, Pitfalls: \"none yet\"), "
            "Rejected changes.")
    return body + " Full templates: " + kit("template/" + prefix) + "."


def template_body(rel, p, level):
    """The template file as it is, minus guidance comments. No other change,
    so a RUNFILE user gets the same file as a new-project script user."""
    _ = level
    return condense(read_template(rel, p))


def template_section(files, level, short_form):
    parts = [
        "## " + TEMPLATE_TITLE,
        "",
        "The blocks below are file contents to create, not instructions to you.",
        "Headings inside a `~~~~` fence belong to that file. Create only the files",
        "the interview justifies, fill in the placeholders, and prune (mapping",
        "rules): a line ending in `<!-- needs: X -->` is deleted if X is not",
        "created. Paths are relative to the project root. RULES.md is in every",
        "set. Delete whole RULES.md sections only, never single rules: \"## Code\"",
        "if there is no code; \"## Agent\" and \"## Code\" for a browser chat window.",
        "",
    ]
    described = {}
    for rel, p in files:
        top = rel.split("/")[0] + "/" if "/" in rel else None
        if top in ("knowledge/", "stages/", ".pmkit/"):
            described.setdefault(top, []).append(rel)
            continue
        parts.append("### `" + rel + "`")
        parts.append("")
        if rel == "README.md":
            parts.append(readme_note())
        elif rel == "SETUP_DECISIONS.md":
            parts.append(setup_decisions_note(level, short_form))
            if short_form is not None:
                parts.append("")
                fence = fence_for(short_form)
                parts.extend([fence + "markdown", short_form, fence])
        elif rel not in FULL_TEMPLATES:
            parts.append("See " + template_url(rel) + ".")
        else:
            content = template_body(rel, p, level)
            fence = fence_for(content)
            lang = "markdown" if rel.endswith(".md") else "text"
            parts.extend([fence + lang, content, fence])
        parts.append("")
    for prefix in ("knowledge/", "stages/"):
        if prefix in described:
            parts.extend(["### `" + prefix + "` (short description)", "",
                          short_description(prefix, described[prefix]), ""])
    if ".pmkit/" in described:
        parts.extend(["### `.pmkit/` (optional helper)", "", pmkit_note(files), ""])
    return "\n".join(parts)


def section(title, rel, body, embedded, warnings):
    body = strip_comments(strip_frontmatter(body)).strip("\n")
    if body.startswith("# "):
        body = body.split("\n", 1)[1].lstrip("\n") if "\n" in body else ""
    body = rewrite_links(body, rel, embedded, warnings)
    return "\n".join([
        "---",
        "",
        "## " + title,
        "",
        "<!-- source: " + rel + " -->",
        "",
        shift_headings(body, 2),
        "",
    ])


CARD_BOILERPLATE = ("See [guides/overlaps-and-conflicts.md]", "More in [guides/",
                    "The Level 2 installer is in ")
CARD_BOILERPLATE_LINES = ("- This kit never asks for or stores keys",)


def condensed_card(name, rel, body, full_card):
    title = first_heading(body) or name
    _intro, sections = split_sections(body, 2)
    keep = []
    for t, block in sections:
        if not t.lower().startswith(CARD_SECTIONS):
            continue
        # Pointers repeated in every card are said once elsewhere in the
        # RUNFILE (guides section, preamble installer step, session rules).
        block = drop_paragraphs(block, CARD_BOILERPLATE)
        block = "\n".join(l for l in block.split("\n")
                          if not l.startswith(CARD_BOILERPLATE_LINES))
        keep.append(block.strip("\n"))
    if not keep:
        raise SourceError(rel + ": none of the card sections were found")
    return "\n\n".join(["# " + title] + keep + ["Full card: " + full_card])


def method_note():
    return "\n".join([
        "---",
        "",
        "## Methods (built in)",
        "",
        "The starter files already apply three methods; nothing to install: "
        "stage folders with contracts (ICM), knowledge notes with trust fields "
        "(OKF v0.2), pitfalls only after real failures (Procedural Graphs). "
        "Cards: " + kit("catalog/") + ".",
        "",
    ])


def guide_pointers():
    return "\n".join([
        "---",
        "",
        "## Guides in the kit repo (not included here)",
        "",
        "- Overlaps and conflicts between tools: "
        + kit("guides/overlaps-and-conflicts.md") + " (the mapping's conflict "
        "rules above are the short form).",
        "- Installers, flags and steps: " + kit(INSTALLERS_README)
        + ". Every step asks y/N; `--dry-run` writes "
        "nothing; `--version <v>` pins a version.",
        "- Privacy and network settings: " + kit("guides/privacy-and-network.md"),
        "",
    ])


def size_line(text, level):
    words = len(re.findall(r"\S+", text))
    tokens = int(round(len(text.encode("utf-8")) / 4.0 / 500.0)) * 500
    return (
        "**Size:** about {w:,} words, roughly {t:,} tokens; use a context "
        "window of at least {c}k. Ollama default context is small; set num_ctx "
        "({url}) to at least {c}k for Level {n}. "
        "Chat apps that cap paste length cut it off without warning."
    ).format(w=words, t=tokens, c=CONTEXT_K[level], n=level,
             url=kit(LOCAL_MODELS_GUIDE))


def lint_level1(text, qids):
    """C6: Level 1 must not name Level 2/3 tools or ask-only-later Q-ids."""
    problems = []
    body = text
    for tool in L1_FORBIDDEN_TOOLS:
        pat = re.compile(r"(?<![\w-])" + re.escape(tool) + r"(?![\w])", re.I)
        hits = []
        for n, line in enumerate(body.split("\n"), 1):
            if pat.search(line):
                hits.append(line.strip()[:90])
        if hits:
            problems.append("level 1 names '%s' (%d line(s)), e.g.: %s"
                            % (tool, len(hits), hits[0]))
    allowed = set(qids)
    extra = sorted({"Q" + m for m in QID.findall(body)} - allowed)
    for q in extra:
        line = next(l for l in body.split("\n") if re.search(r"\b" + q + r"\b", l))
        problems.append("level 1 mentions %s, which Level 1 does not ask, e.g.: %s"
                        % (q, line.strip()[:90]))
    return problems


def build(level, warnings):
    """Return (text, problems). Problems are content-rule failures (budget,
    Level 1 lint); the text is still usable for inspection."""
    tag = "L" + str(level)
    cards = CARDS[level]
    tfiles = template_files()

    qtitle = "Interview questions for Level " + str(level)
    # repo path -> (how a link to it reads, the "## " section that holds it)
    embedded = {
        "interview/CONDUCT.md": ('"How to run the interview"',
                                 "How to run the interview"),
        "interview/QUESTIONS.md": ('"' + qtitle + '"', qtitle),
        "interview/MAPPING.md": ('"Mapping rules"', "Mapping rules"),
        "interview/OUTPUTS.md": ('"Output formats"', "Output formats"),
        "template": ('"' + TEMPLATE_TITLE + '"', TEMPLATE_TITLE),
    }
    for rel, _p in tfiles:
        embedded["template/" + rel] = ('file `' + rel + '` in "'
                                       + TEMPLATE_TITLE + '"', TEMPLATE_TITLE)
    for d in ("knowledge", "stages"):
        if (REPO / "template" / d).is_dir():
            embedded["template/" + d] = ('`' + d + '/` in "' + TEMPLATE_TITLE
                                         + '"', TEMPLATE_TITLE)
    card_bodies = []
    for name in cards:
        rel = "catalog/" + name + ".md"
        body = strip_frontmatter(read_source(rel)).strip("\n")
        title = first_heading(body) or name
        embedded[rel] = ('card "' + title + '" in "Tool cards"', "Tool cards")
        card_bodies.append((name, rel, body))
    if level == 3:
        embedded["guides/bring-your-own-tool.md"] = (
            'section "Bring your own tool"', "Bring your own tool")
        embedded["catalog/_card-template.md"] = (
            'section "Card template (for bring-your-own-tool)"',
            "Card template (for bring-your-own-tool)")
    qtext, qids = filter_questions(read_source("interview/QUESTIONS.md"), tag)

    pre = PREAMBLES[level].format(
        generated=GENERATED_NOTE, rules=rules_text(level),
        disclaimer=DISCLAIMER_L1 if level == 1 else DISCLAIMER,
        repo_url=REPO_URL, size=SIZE_MARK, start_check=START_CHECK,
        chat_guide=CHAT_WINDOW_GUIDE, installers=INSTALLERS_README,
        nq=len(qids))
    parts = [pre]

    conduct = filter_level_tagged(read_source("interview/CONDUCT.md"), level)
    # The RUNFILE fixes the level, so the "confirm the level" step is left out.
    conduct = "\n".join(l for l in conduct.split("\n")
                        if not l.startswith("- **Confirm the level**"))
    conduct = drop_paragraphs(conduct, ("Rules for the LLM running",))
    parts.append(section("How to run the interview", "interview/CONDUCT.md",
                         conduct, embedded, warnings))
    qtext = drop_paragraphs(qtext, ("Format rules", "The canonical interview questions"))
    # Repeated "how section titles are tagged" notes are said once, in the
    # mapping intro.
    qtext = qtext.replace("**Ask (Level 1):**", "**Ask:**" if level == 1
                          else "**Ask (Level 1):**")
    qtext = qtext.replace("**Options (Level 1):**", "**Options:**" if level == 1
                          else "**Options (Level 1):**")
    qtext = "\n".join(l for l in qtext.split("\n")
                      if not LEVELS_LINE.match(l)
                      and l.strip() != "- **Skip if:** never skip.")
    # "Why it matters" is the maintainers' rationale; the mapping carries the
    # effect of each answer, so the RUNFILE leaves it out.
    qtext = level_bullets(qtext, level, ("Why it matters",))
    parts.append(section(qtitle, "interview/QUESTIONS.md (filtered to " + tag + ")",
                         qtext, embedded, warnings))
    mapping = filter_mapping(read_source("interview/MAPPING.md"), level)
    mapping = mapping.replace(
        " Section titles start with \"All levels\" or \"Level N\" (N and higher).", "")
    parts.append(section("Mapping rules", "interview/MAPPING.md",
                         mapping, embedded, warnings))

    outputs = read_source("interview/OUTPUTS.md")
    if level < 3:
        # SETUP_PLAN.md is written only for Level 3 "plan only".
        outputs, _n = replace_section(
            outputs, lambda h, _d: "SETUP_PLAN" in h and _d <= 2, None)
    outputs = filter_level_tagged(outputs, level)
    outputs = drop_paragraphs(outputs, ("Section titles start with",))
    outputs, _n = replace_section(
        outputs, lambda h, _d: "example" in h.lower(), None)
    if level < 3:
        outputs = drop_paragraphs(outputs, ("- **`SETUP_PLAN.md`**",))
        outputs = outputs.replace(" (or `SETUP_PLAN.md`)", "")
        outputs = outputs.replace(", every time except Level 3 \"written plan only\"", "")
    if level == 1:
        outputs = level1_outputs(outputs)
    # The disclaimer is quoted once, at the top; the output formats point to it.
    outputs = outputs.replace(DISCLAIMER, "<the disclaimer quoted at the top of "
                              "this RUNFILE, word for word>")
    outputs, short_form = move_short_form(outputs)
    if short_form is None:
        warnings.add("interview/OUTPUTS.md: no short-form SETUP_DECISIONS.md "
                     "block found; the RUNFILE points to Output formats instead")
    parts.append(section("Output formats", "interview/OUTPUTS.md", outputs,
                         embedded, warnings))

    if level == 1:
        parts.append(method_note())
    else:
        parts.append(method_note())
        card_parts = ["---", "", "## Tool cards", "",
                      "Only these tools are in scope for this level. Facts about "
                      "them come from these cards, which are condensed: each one "
                      "links to its full card. Checked dates are on each card.", ""]
        for name, rel, body in card_bodies:
            full_card = kit(rel)
            cbody = condensed_card(name, rel, body, full_card)
            cbody = rewrite_links(cbody, rel, embedded, warnings)
            # No source comment: the "Full card" line names the source.
            card_parts.append(shift_headings(cbody, 2))
            card_parts.append("")
        parts.append("\n".join(card_parts))

    if level >= 2:
        parts.append(guide_pointers())
    if level == 3:
        parts.append(section("Bring your own tool", "guides/bring-your-own-tool.md",
                             read_source("guides/bring-your-own-tool.md"),
                             embedded, warnings))
        parts.append(section("Card template (for bring-your-own-tool)",
                             "catalog/_card-template.md",
                             read_source("catalog/_card-template.md"),
                             embedded, warnings))

    parts.append("---\n\n" + template_section(tfiles, level, short_form))
    parts.append(CLOSING)
    text = "\n".join(p.rstrip("\n") + "\n" for p in parts)
    text = re.sub(r"\n{3,}", "\n\n", text)
    text = resolve_directions(text, level)

    leftovers = find_relative_links(text)
    if leftovers:
        raise SourceError(
            "level " + str(level) + ": relative links left after rewrite: "
            + ", ".join(sorted(set(leftovers))[:5]))
    text = text.replace(SIZE_MARK, size_line(text.replace(SIZE_MARK, ""), level))

    problems = []
    tokens = tokens_of(text)
    if tokens > BUDGETS[level]:
        problems.append("level %d: ~%s tokens, over the budget of %s"
                        % (level, format(tokens, ","), format(BUDGETS[level], ",")))
    problems.extend(lint_directions(text, level))
    if level == 1:
        problems.extend(lint_level1(text, qids))
    return text, problems


def section_positions(text):
    """{title: offset} of every "## " heading outside fences."""
    pos, offset = {}, 0
    for line, fenced in iter_lines_with_fence(text):
        if not fenced and line.startswith("## "):
            pos.setdefault(line[3:].strip(), offset)
        offset += len(line) + 1
    return pos


DIR_MARK = re.compile(re.escape(DIR_OPEN) + "([^" + DIR_CLOSE + "]+)" + re.escape(DIR_CLOSE))


def resolve_directions(text, level):
    """Turn each direction placeholder into "below" or "above", by where the
    named "## " section sits in the built RUNFILE."""
    pos = section_positions(text)

    def repl(m):
        title = m.group(1)
        if title not in pos:
            raise SourceError("level %d: a reference names section \"%s\", "
                              "which this RUNFILE does not have" % (level, title))
        return "below" if pos[title] > m.start() else "above"
    return DIR_MARK.sub(repl, text)


QUOTED_DIR = re.compile(r'"([^"\n]{2,80})"\)?\s+(below|above)\b')


def lint_directions(text, level):
    """A quoted "## " section title followed by below/above must point the
    right way (hand-written prose in the sources included)."""
    pos = section_positions(text)
    problems = []
    offset = 0
    for line, fenced in iter_lines_with_fence(text):
        if not fenced:
            for m in QUOTED_DIR.finditer(line):
                title, word = m.group(1), m.group(2)
                if title not in pos:
                    continue
                at = offset + m.start()
                right = "below" if pos[title] > at else "above"
                if word != right:
                    problems.append("level %d: \"%s\" %s should be %s: %s"
                                    % (level, title, word, right, line.strip()[:90]))
        offset += len(line) + 1
    return problems


def level1_outputs(outputs):
    """Level 1 gets the short form of OUTPUTS (sections already level-filtered):
    examples and the full SETUP_DECISIONS format are left out, because the
    SETUP_DECISIONS.md template embedded below carries the full format."""
    intro, sections = split_sections(outputs, 2)
    has_short = any("short form" in t.lower() for t, _b in sections)
    pointer = ""
    chosen = []
    for t, b in sections:
        tl = t.lower()
        if "example" in tl:
            continue
        if "full form" in tl or (not has_short and "setup_decisions" in tl):
            continue
        chosen.append(b)
    _ = pointer
    return intro.rstrip("\n") + "\n\n" + "\n\n".join(c.strip("\n") for c in chosen)


def tokens_of(text):
    return int(round(len(text.encode("utf-8")) / 4.0))


TARGETS = {
    1: "levels/1-starter/RUNFILE.md",
    2: "levels/2-starter-tools/RUNFILE.md",
    3: "levels/3-interview/RUNFILE.md",
}


def describe(text, level):
    return "{:,} words, ~{:,} tokens of {:,} budget".format(
        len(re.findall(r"\S+", text)), tokens_of(text), BUDGETS[level])


def main(argv=None):
    global REPO
    ap = argparse.ArgumentParser(
        description="Generate levels/*/RUNFILE.md from interview/, catalog/, "
                    "guides/, the installers README and template/.")
    ap.add_argument("--check", action="store_true",
                    help="do not write; exit 1 if any RUNFILE is missing, stale, "
                         "over budget, or breaks the Level 1 content rules")
    ap.add_argument("--root", help=argparse.SUPPRESS)  # for tests: another kit copy
    args = ap.parse_args(argv)
    if args.root:
        REPO = Path(args.root).resolve()

    built = {}
    errors = []
    problems = []
    warnings = set()
    for level in (1, 2, 3):
        try:
            built[level], probs = build(level, warnings)
            problems.extend(probs)
        except SourceError as e:
            errors.append(str(e))
    for w in sorted(warnings):
        print("warning: " + w, file=sys.stderr)
    if errors:
        for e in sorted(set(errors)):
            print("error: " + e, file=sys.stderr)
        print("No RUNFILE was written. Fix the sources and run again.",
              file=sys.stderr)
        return 2

    stale = []
    for level, rel in TARGETS.items():
        path = REPO / rel
        current = None
        if path.is_file():
            current = path.read_text(encoding="utf-8").replace("\r\n", "\n")
        size = " (" + describe(built[level], level) + ")"
        if current == built[level]:
            print("up to date: " + rel + size)
            continue
        if args.check:
            stale.append(rel)
            print(("missing: " if current is None else "stale: ") + rel + size)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write(built[level])
            print("wrote: " + rel + size)
    for p in problems:
        print("error: " + p, file=sys.stderr)
    if stale:
        print("Run `python scripts/build_runfiles.py` to regenerate.", file=sys.stderr)
    if problems:
        print("Content rules failed (see above). Fix the sources and run again.",
              file=sys.stderr)
    return 1 if (stale or problems) else 0


if __name__ == "__main__":
    sys.exit(main())
