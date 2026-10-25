# Changelog

Notable changes to pmkit. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [0.1.1] - 2026-10-24

Policies, enforcement and a docs site. No kit behavior changes.

### Added

- `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), with a private reporting channel.
- DCO sign-off: required in CONTRIBUTING, checked by a CI job on every pull request.
- `docs/` landing page, published to GitHub Pages automatically on every push to `main`.

### Changed

- Blank issues disabled; the issue page now routes to the contributing guide and the conduct channel.

## [0.1.0] - 2026-10-17

The first version. It is early, and untested parts are labelled.

### Added

#### Who it is for

- A solo person or single owner running an AI agent on a folder of code, research or writing.
- A lighter path for browser chat-window users in `guides/chat-window.md`: `PROJECT.md`, `STATUS.md` and `RULES.md`, plus a short `SETUP_DECISIONS.md` (and, for research, an optional `SOURCES.md`).
- Planned for v0.2, not yet supported: teams on parallel branches, and enterprise or document-compliance pipelines.

#### Levels, layers and the interview

- Three levels, each starting with an interview: Level 1 Starter, Level 2 Starter + tools, Level 3 Interview-led. Level 3 first asks whether you want a written plan only, or a plan plus the files.
- Three layers, Method, Tool and Service, separate from the levels. The upkeep you say you will keep up caps how many files and tools you get.
- `interview/`: question bank, answer-to-recommendation mapping (split into "All levels" and per-level sections), output formats, and rules for how the LLM runs the interview.
- Level 1 asks a short data-sensitivity question; nothing is routed to a cloud model without it.
- Before proposing files, the interview looks for conventions the project already has (ADRs, CONTRIBUTING, existing agent instruction files, CI review bots) and reuses them.

#### Starter folder (`template/`)

- `AGENTS.md`, `RULES.md`, `PROJECT.md`, `STATUS.md`, `DECISIONS.md`, `LOG.md`, `SETUP_DECISIONS.md`, a `.gitignore`, an optional OKF v0.2 `knowledge/` folder, optional ICM-style `stages/`, and `.pmkit/pmkit.py` (sync, check, prune, log, decide). For code in git, `LOG.md` is optional.
- `RULES.md`: short working rules in every minimal set, read first through `AGENTS.md`. Four sections, numbered straight through: General, Documentation, Agent and Code.
  - Documentation rules name "the project's decision record", so they work with `DECISIONS.md` or existing ADRs.
  - Code rules apply to new code, and an existing project's style wins. The step-by-step gate (brainstorm, spec, plan, implement) applies to features and multi-file work, not small fixes.
  - A chat-window set keeps General and Documentation only; non-code projects drop Code. The interview may delete sections but never rewrites the owner's rules.
- `needs:` markers on template lines that depend on optional files. `pmkit.py prune` removes those lines when the file was not kept, and repoints the "Why is it like this?" row to `docs/adr/` or `docs/decisions/` when one exists, instead of deleting it.
- `pmkit.py check`:
  - Warns about `needs:` lines, relative links to missing files, and leftover placeholders (including an unfilled `SETUP_DECISIONS.md`).
  - Fails when `PROJECT.md`, `STATUS.md`, `RULES.md` or a file `AGENTS.md` routes to is missing. A routing-table cell counts as a route only when it holds a markdown link or a path in backticks.
  - Fails when a `see D-###` pointer names a decision missing from an existing `DECISIONS.md`. Without `DECISIONS.md`, a pointer hit is a warning. `.pmkit/ignore.txt` (one glob per line) skips paths in the pointer scan.
  - Apart from the pointer scan, it only checks files the kit created, and it tells you when it finds a chat-window set instead of failing.
- Adapters off by default (`.pmkit/adapters.txt`), with `import` and `copy` modes. Suggested for Claude Code: a `CLAUDE.md` that imports `AGENTS.md`.
  - Generated adapters carry a hash of their content. `check` warns (it does not fail) when one was edited, because Claude Code's `/init` (and `#` memory, in versions that have it) write to `CLAUDE.md`.
  - `sync` will not overwrite an edited adapter: it shows a diff and asks you to merge the edit into `AGENTS.md` and run `sync --force`.

#### Catalog and guides

- Tool cards (`catalog/`) for ICM, OKF, Procedural Graphs, Archify, graphify, Open Code Review, LangExtract, Strix, and the fallback workflow-graph. All checked 2026-10-17.
- Guides: chat window, overlaps and conflicts, local models (including how to set the context window), adding tools mid-project, bring your own tool, privacy and network, what this is not.

#### Scripts

- Level 2 installers in bash and Windows PowerShell for Archify, graphify, Open Code Review and LangExtract, plus a local model check. Each accepts `--version` / `-Version` to pin, and prints the version it installed. The "log it" step applies only if `LOG.md` exists.
- Claude Code skill `project-setup` and `scripts/install-skill.*`.
- `scripts/new-project.*` copies the starter files without overwriting anything.
  - `--minimal` / `-Minimal` and `--only` / `-Only` copy fewer files.
  - When `.pmkit/` is copied, it shows `prune --dry-run` before pruning and asks first unless `--yes` is given.
  - Its "Next steps" depend on whether `SETUP_DECISIONS.md` is already filled in, and its `.gitignore` suggestions skip lines your file already covers.
- `scripts/build_runfiles.py` generates a paste-anywhere RUNFILE for each level. RUNFILEs embed the actual template files, so the script and the RUNFILE give you the same files. Size budgets are 7.5k / 15k / 23k tokens (measured as bytes / 4; currently roughly 7k / 15k / 21k), enforced by `--check`.
