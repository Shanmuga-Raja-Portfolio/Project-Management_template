# Archify

## One-liner

An agent skill that turns a plan or repo into a checked, self-contained HTML diagram. Your agent writes the diagram as JSON; Archify validates and renders it.

## Layer

**Tool.** Local Node.js skill, writes files, no daemon.

Available at Level 2 (installer) and Level 3.

## What it does

- Your host agent (Claude Code, Codex CLI, opencode; Cursor is an install target too) reads Archify's `SKILL.md` and writes typed JSON for one diagram type.
- 10 diagram types: Architecture, Workflow, Sequence, Data Flow, Lifecycle, ERD, Class, Tree, Timeline, Waterfall. Plus an Architecture Delta mode for before/after comparison.
- Bundled Node validators check the JSON. Each problem comes back with a stable rule code (for example `schema/required`) and a short fix hint in plain language. The agent repairs and re-checks, up to 2 rounds.
- `deliver` renders a candidate, checks it, then replaces the target file with one self-contained HTML file. It opens without Archify installed.
- An optional preview session watches one JSON file and binds to `127.0.0.1` only.
- Archify makes no LLM calls itself.

## What it does NOT do

- Not a knowledge graph, memory store or code analyser. It draws the picture your agent describes.
- No automatic Mermaid parsing, general-purpose auto-layout, hosted sharing or drag-and-drop editing (stated out of scope).
- Fix hints are instructions for the agent, not patches Archify applies.
- It does not check that the diagram matches your real code. For that, compare with graphify (see Conflicts).

## Use when (triggers)

Only when the trigger holds now:

- A review or stakeholder meeting that is actually scheduled needs an architecture or workflow picture, and a Mermaid block was tried and was not clear enough.
- You need to show an architecture change before and after now (Delta mode).

Add later (not at setup): a diagram for a future handoff or onboarding. Put it under "Add later" in `SETUP_DECISIONS.md` with the handoff date or milestone, and install Archify when that date comes.

## Skip when

- Nobody will read the diagram.
- A hand-written Mermaid block in markdown is enough. That is the default: zero install, diffable.
- No Node.js on the machine.

## Install

Needs Node.js 18 or newer (`npx`).

```bash
npx skills add tt-a1i/archify -g
```

From a clone (the CLI lives under `archify/`):

```bash
cd archify
node bin/archify.mjs doctor
```

The Level 2 installer is in [`levels/2-starter-tools/installers/`](../levels/2-starter-tools/installers/README.md) (`archify.sh` / `archify.ps1`). It asks before each step and writes a privacy-safe env example to `.pmkit/env/archify.env.example`.

Version seen at check: v3.1.0 (released 2026-10-13). The repo changes daily. The installer installs the latest release and prints the version it found. The `skills` CLI has no documented way to choose a version, so `--version <v>` (`-Version <v>` in PowerShell) cannot pin: it checks the installed version and stops with an error if it differs. Record the version you install in `SETUP_DECISIONS.md` under "Installed tools".

## Files/settings it touches

| Command | Writes |
|---|---|
| `npx skills add tt-a1i/archify -g` | The skill folder in your agent's global skills directory. Paths per agent: Claude Code `~/.claude/skills/` (project: `.claude/skills/`); Codex CLI `~/.agents/skills/` (project: `.agents/skills/`); opencode `~/.config/opencode/skills/` (project: `.opencode/skills/` or `.agents/skills/`) |
| `deliver` | The HTML file you name, replaced atomically. A candidate file is written in the same directory first |
| Update reminder | Reminder-state writes (turned off by `ARCHIFY_UPDATE_CHECK_DISABLED=1`) |
| Preview session | Nothing persistent; local server on `127.0.0.1` |

## Network calls & data leaving the machine

- Install: `npx` downloads the package and skill.
- Update check (optional): one GET to `https://tt-a1i.github.io/archify/skill-updates/archify/stable.json`. It sends only an `Accept` header. The server still sees your IP address and the time. `ARCHIFY_UPDATE_CHECK_DISABLED=1` turns it off.
- No other outbound fetch was found in Archify's own scripts.
- Your diagram content goes wherever your host agent's model runs.
- Generated HTML may contain external links. They make a request only when a viewer clicks them.

## API keys

None. Archify uses your host agent's model.

## Local model route (exact env vars)

No Archify env vars for models. It inherits the host agent's model. If your agent runs a local model, Archify works only if that model can produce JSON that passes the validators. That is not documented, and small models may fail. See [guides/local-models.md](../guides/local-models.md).

## Privacy-safe settings

```bash
ARCHIFY_UPDATE_CHECK_DISABLED=1
```

Archify's README has a sponsors section promoting third-party discounted API resellers and relays. Archify does not need them. Do not route your API keys through such services.

## Conflicts/overlaps

- **Mermaid**: the default. Use Archify only when Mermaid is not clear enough.
- **graphify** `graph.html` shows the structure that exists; Archify draws the one you intended. They will disagree. Use that as a review input. Do not auto-sync one into the other.
- **workflow-graph** is the fallback for live DAG status inside an existing web UI. See [workflow-graph.md](workflow-graph.md).

See [guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md).

## Cost & risk

- Setup: one `npx` command.
- Token cost: the agent writes JSON and repairs it. Grows with diagram size.
- A skill instructs your agent. Read `SKILL.md` before installing.
- Maturity: repo created 2026-04-15, very active. The installer cannot pin a version (see above); record the version it prints in `SETUP_DECISIONS.md`.
- License has two copyright holders (tt-a1i and Cocoon AI), which suggests the code builds on earlier Cocoon AI work.

## Upstream link

<https://github.com/tt-a1i/archify> (MIT)

## Checked: 2026-10-17

## Unverified

- Whether small or local models can reliably produce JSON that passes validation.
- Full renderer and validation support on Cursor (implied, not stated in the README's support table).
- Exactly which directory `-g` writes to for each agent depends on the `skills` CLI. Check its output.
- How the `skills` CLI pins a specific skill version (not covered by the research).
