# ICM (Interpretable Context Methodology) and icm-template

## One-liner

Folder and markdown conventions that split repeatable work into numbered stages, each with a short contract, so the agent loads only what the current stage needs.

## Layer

**Method.** Plain markdown, nothing to run.

Available at every level. This kit's `template/stages/` folder is an ICM-style adaptation, so you do not need to install anything to use the idea.

## What it does

**ICM** (RinDig) is a convention, not software:

- A workspace has `CONTEXT.md` files for routing ("for this task, read that").
- Work runs through numbered folders, `stages/NN-name/`. Each stage has a `CONTEXT.md` contract (Inputs / Process / Outputs), a `references/` folder and an `output/` folder. Each stage's output feeds the next.
- Context loads in five layers: the always-loaded instruction file, the workspace routing file, the stage contract, then reference material and working files only as needed.
- Humans can edit any intermediate file. Creative stages add checkpoints; audits act as pass/fail gates.
- Typing `setup` in Claude Code runs a one-time onboarding questionnaire. It has conditional branches, not a flat list.
- `_core/CONVENTIONS.md` lists 15 conventions (stage contracts, stage handoffs, one-way cross-references, canonical sources, "CONTEXT.md is routing, not content", checkpoints, stage audits and others).
- It ships 4 workspace folders: 3 examples plus `workspace-builder`, which has 5 stages for building new workspaces.

**icm-template** (ktnCodes) is one implementation of ICM, not a separate method:

- Adds `IDENTITY.md` (workspace map plus 3 to 7 rules), a root `CONTEXT.md` (routing table, session-start protocol, pipeline) and `_config/` (conventions, glossary, voice).
- Three Claude Code skills: `/icm-scaffold` (6 required interview questions plus 4 optional; quick mode with 3 layers, full mode with stage folders), `/icm-sync` (asks the LLM to compare routing files with what is on disk; flags stale entries instead of deleting them; has a report-only `lint` mode) and `/icm-context-scaffold` (creates missing `CONTEXT.md` files).
- Optional adapters copy `IDENTITY.md` into `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md` or `.windsurfrules`, with a "do not edit" header.

**How this kit uses it:**

- `AGENTS.md` is the one canonical instruction file. Adapters such as `CLAUDE.md` are optional and none is enabled by default. If you enable one in `.pmkit/adapters.txt`, `python .pmkit/pmkit.py sync` generates it. This kit does not use `IDENTITY.md`.
- `template/stages/` holds optional stages with the same Inputs / Process / Outputs contract, plus a Pitfalls section (see [procedural-graphs.md](procedural-graphs.md)).
- See [template/stages/README.md](../template/stages/README.md).

## What it does NOT do

- No runtime, memory, retrieval, code analysis or graph features.
- It does not enforce anything. "Never restructure existing folders", token targets and "keeps routing accurate" are instructions in prompts. Nothing measures or blocks them.
- `/icm-sync` is best-effort LLM reconciliation, and only when you run it. Accuracy depends on the model.
- Quick mode still adds files at the project root (`IDENTITY.md`, `CONTEXT.md`, `_config/`, optional adapters).
- It is not for real-time multi-agent work, high-concurrency systems or complex automated branching (ICM README).

## Use when (triggers)

- The same multi-step deliverable is being produced a 2nd or 3rd time (content pipeline, course, report series).
- The agent keeps mixing up stages or loading material from the wrong step.
- Existing repo that needs orientation without moving files: icm-template quick mode, or only this kit's `AGENTS.md` routing table.

## Skip when

- One-off task, or an ongoing product without repeated multi-step deliverables. A README plus `AGENTS.md` is enough. Delete `stages/` (and run `python .pmkit/pmkit.py prune` if `.pmkit/` is present, so `AGENTS.md` stops pointing to it).
- You will not keep the stage contracts up to date (the interview's upkeep question, Q07).

## Install

In this kit: nothing. Keep or delete `stages/` when the project folder is created.

Upstream ICM (optional, to read the examples):

```bash
git clone https://github.com/RinDig/Interpretable-Context-Methodology
cd Interpretable-Context-Methodology/workspaces/<name>
# open Claude Code here and type: setup
```

Upstream icm-template (optional, Claude Code only):

```bash
git clone https://github.com/ktncodes/icm-template.git
cp -r icm-template/SKILLS/icm-scaffold ~/.claude/skills/icm-scaffold
cp -r icm-template/SKILLS/icm-sync ~/.claude/skills/icm-sync
cp -r icm-template/SKILLS/icm-context-scaffold ~/.claude/skills/icm-context-scaffold
# then run /icm-scaffold inside the project
```

icm-template has 2 commits and no releases. Default branch is `master`. Last activity 2026-04-14.

## Files/settings it touches

| Command | Writes |
|---|---|
| This kit's `stages/` | Only the files you keep from `template/stages/` |
| Copying icm-template skills | `~/.claude/skills/icm-scaffold/`, `icm-sync/`, `icm-context-scaffold/` |
| `/icm-scaffold` quick mode | `IDENTITY.md`, `CONTEXT.md`, `_config/` at the project root; adapters if chosen (`CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, `.windsurfrules`) |
| `/icm-scaffold` full mode | The above plus `stages/NN_name/` with `CONTEXT.md`, `references/`, `output/` |
| `/icm-sync update` | Edits `IDENTITY.md`, `CONTEXT.md`, sub-folder `CONTEXT.md` files; regenerates adapters |

## Network calls & data leaving the machine

- None of its own. It is markdown.
- Your files go wherever your agent's model runs (for Claude Code, Anthropic's cloud).
- `git clone` downloads from GitHub.

## API keys

None of its own. It needs whatever your agent already needs.

## Local model route (exact env vars)

No env vars. Nothing executes.

- ICM documents no local-model setup. Its conventions assume Claude Code (`CLAUDE.md` auto-load, skills in `~/.claude/skills/` or `~/.agents/skills/`).
- icm-template's documented manual route: paste `IDENTITY.md` into the system prompt and add the stage's `CONTEXT.md` at the start of each session.
- With this kit: paste `AGENTS.md` and the current stage's `CONTEXT.md` into the local model's chat. See [guides/local-models.md](../guides/local-models.md).

## Privacy-safe settings

Nothing to set. Keep secrets out of stage files and `references/`, because the agent reads them.

## Conflicts/overlaps

- **Several root instruction files competing** (`CLAUDE.md`, `AGENTS.md`, `IDENTITY.md`, `CONTEXT.md`, `.cursorrules`). Pick one canonical file. In this kit that is `AGENTS.md`. If you also run icm-template, do not let it generate adapters; they would fight with `pmkit.py sync`.
- What happens when `/icm-scaffold` finds an existing `CLAUDE.md` or `.cursorrules` is not documented. Back them up first.
- Running `/icm-sync` and `graphify install` (which appends to `CLAUDE.md`) on the same file causes churn.
- Stage contracts and OKF concepts are different units. Do not put OKF frontmatter on stage outputs.
- ICM is the container; Procedural Graphs pitfalls go inside stage contracts. They do not compete.

See [guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md).

## Cost & risk

- No install, no money. Token cost only: each stage loads a small contract instead of everything.
- The ICM token figures (2k-8k per stage vs 30k-50k monolithic) are illustrative. The paper says no controlled comparison was run. This kit does not rely on them.
- The ICM paper says the method is model-agnostic, but all testing used Claude models.
- Review any bundled skill before copying it into a workspace. Skills instruct your agent.

## Upstream link

- ICM: <https://github.com/RinDig/Interpretable-Context-Methodology> (MIT). Paper: arXiv 2603.16021.
- icm-template: <https://github.com/ktnCodes/icm-template> (MIT)

## Checked: 2026-10-17

## Unverified

- Contents of the course-deck and voice-driven-animation workspaces, and of the stage subfolders.
- Whether example workspaces need Python, ffmpeg or LibreOffice. Only optional Remotion is confirmed.
- That the method works as well on non-Claude models.
- The ICM README and paper disagree on the title (MWP vs ICM) and the author list.
- icm-template behaviour when `CLAUDE.md` or `.cursorrules` already exist.
- icm-template's token targets disagree inside the repo (README/docs: ~800 / ~300; skills: under 1,500 / under 2,000).
