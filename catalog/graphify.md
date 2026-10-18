# graphify

## One-liner

Builds a knowledge graph of a code folder (and optionally docs) that an agent can query instead of re-reading files.

## Layer

**Tool** in code-only mode (`GRAPHIFY_BACKEND=none`). It becomes a **Service** when the semantic pass uses a cloud backend.

Level 2 installs code-only mode only.

## What it does

- Parses code locally with tree-sitter (about 40 languages; some need optional extras). No LLM is used for code.
- Optionally runs a semantic pass over docs, PDFs and images through an LLM.
- Clusters the graph (Leiden). No embeddings, no vector database.
- Tags edges `EXTRACTED` (found in source) or `INFERRED` (a guess, with a confidence score).
- Writes output files to `graphify-out/`: `graph.json`, `GRAPH_REPORT.md`, `graph.html`, plus `cache/`.
- Has `query`, `path` and `explain` commands over `graph.json`, and an MCP server (`graphify-mcp`, needs the `mcp` extra).
- A per-file SHA256 cache means re-runs only process changed files.

## What it does NOT do

- It is not a project-management, planning or memory system.
- It does not draw the architecture you intended. It shows the structure that exists.
- `INFERRED` edges are LLM guesses. They are not facts.
- Bare `graphify install` does not detect your assistant. It defaults to Claude Code.

## Use when (triggers)

- The agent re-reads or greps the same files every session.
- The codebase is beyond what you can hold in your head (rough guide: tens of thousands of lines, or many modules).
- You are inheriting an unfamiliar repo.
- Semantic pass only: you need cross-links between docs, specs and code, and a local model or an approved cloud provider is configured.

## Skip when

- Greenfield or small repo. Reading the files is cheaper and clearer.
- Docs are sensitive and no local model is set up (code-only mode is still fine).

## Install

PyPI name is **`graphifyy`** (double y). The command is `graphify`. Other `graphify*` packages on PyPI are not affiliated. Type the name exactly.

Requires Python 3.10+.

```bash
uv tool install graphifyy      # or: pipx install graphifyy
```

Code-only graph, no LLM, runs offline:

```bash
GRAPHIFY_BACKEND=none graphify extract .
```

The Level 2 installer is in [`levels/2-starter-tools/installers/`](../levels/2-starter-tools/installers/README.md) (`graphify.sh` / `graphify.ps1`). It installs the package only. It does not run `graphify install` or `graphify hook install` unless you say yes at a separate prompt.

Optional, and each one changes files outside `graphify-out/` (see next section):

```bash
graphify install          # registers the /graphify skill (Claude Code by default)
graphify hook install     # rebuild graph on commit / checkout
```

Version seen at check: v0.9.92 (2026-10-16). Releases come every few days. The installer installs the latest release by default and prints the exact version. To pin one, pass `--version <v>` (`-Version <v>` in PowerShell), or by hand: `uv tool install graphifyy==<v>` (or `pipx install graphifyy==<v>`). Record the version you install in `SETUP_DECISIONS.md` under "Installed tools".

## Files/settings it touches

| Command | Writes |
|---|---|
| `graphify extract` / `/graphify .` | `graphify-out/` in the project (`graph.json`, `GRAPH_REPORT.md`, `graph.html`, `cache/`) |
| `graphify install` (bare, Claude) | Copies `SKILL.md` + `references/` to `~/.claude/skills/graphify/` (or `$CLAUDE_CONFIG_DIR`, or `.claude/skills/` with `--project`). **Appends a registration block to `~/.claude/CLAUDE.md`** (or `.claude/CLAUDE.md`). Lock file under `~/.cache/graphify/skill-locks/` |
| `graphify <platform> install` (always-on setups) | PreToolUse hooks in Claude settings, `AGENTS.md`, `.cursor/rules`, `.gemini/settings.json`, `.codex/hooks.json`, depending on platform |
| `graphify hook install` | Marker-delimited blocks in 4 git hooks: `post-commit`, `post-checkout`, `post-merge`, `post-rewrite` (respects `core.hooksPath` and Husky). **Runs `git config merge.graphify.*`** (a union merge driver for `graph.json`). **Edits `.gitattributes`** (a tracked file) |
| `graphify provider add` | `~/.graphify/providers.json` |
| Query log (off by default) | `~/.cache/graphify-queries.log` only if you set `GRAPHIFY_QUERY_LOG_ENABLE=1` |

In this kit, `AGENTS.md` is the one canonical instruction file. A project `CLAUDE.md`, if you enabled one, is a generated adapter (by default a header line plus `@AGENTS.md`). If you run `graphify install`, its block lands in `~/.claude/CLAUDE.md` (user level), not in the project adapter. If you point it at a generated project adapter, the next `.pmkit/pmkit.py sync` refuses for that file because its body no longer matches its recorded hash; you then have to merge the edit into `AGENTS.md` and run `sync --force`. Keep graphify's block out of generated files.

## Network calls & data leaving the machine

- **Code-only (`GRAPHIFY_BACKEND=none`)**: nothing leaves the machine. This also disables the `claude -p` labelling fallback.
- **Community labelling** in the standalone CLI sends the top node labels per cluster (code symbol names) to the configured LLM backend. If no key is set but the `claude` CLI is on PATH, it falls back to `claude -p` on your subscription. `GRAPHIFY_BACKEND=none` stops this.
- **Semantic pass** (docs, PDFs, images): content goes to the configured LLM provider.
- **Skill mode (`/graphify`) ignores `GRAPHIFY_BACKEND`.** It uses Gemini if `GEMINI_API_KEY` or `GOOGLE_API_KEY` is set in the environment, otherwise the host agent's own model. So with a Google key set, docs go to Google even inside Claude Code.
- Headless auto-detect order when keys are present: Gemini, Kimi, Claude, OpenAI, DeepSeek, Azure, Bedrock, Ollama. Kimi routes to Moonshot servers in China.
- No telemetry or analytics code was found in the source.
- `graphify install` prints an upsell for the paid Graphify Cloud. The OSS CLI does not need it.

## API keys

- Code-only: none.
- Headless semantic pass needs one of: `GEMINI_API_KEY` / `GOOGLE_API_KEY`, `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `MOONSHOT_API_KEY`, `DEEPSEEK_API_KEY`, `AZURE_OPENAI_API_KEY` + `AZURE_OPENAI_ENDPOINT`, or the AWS credential chain for Bedrock.
- This kit never asks for or stores keys. Set them yourself if you choose a cloud backend.

## Local model route (exact env vars)

Headless CLI only. The `/graphify` skill does not use these.

Ollama (note: graphify wants the `/v1` suffix):

```bash
GRAPHIFY_BACKEND=ollama
OLLAMA_BASE_URL=http://localhost:11434/v1   # default
OLLAMA_MODEL=qwen2.5-coder:7b               # default
# OLLAMA_HOST is also honoured
```

LM Studio or another OpenAI-compatible server:

```bash
GRAPHIFY_BACKEND=openai                     # assumed value; check graphify --help
OPENAI_BASE_URL=http://localhost:1234/v1
OPENAI_MODEL=<model name>                   # GRAPHIFY_OPENAI_MODEL takes precedence
```

Or register an endpoint with `graphify provider add` (stored in `~/.graphify/providers.json`).

The code warns about, but still allows, LAN hosts in `OLLAMA_BASE_URL`. For strictly local use, make sure the URL is `localhost`.

More in [guides/local-models.md](../guides/local-models.md).

## Privacy-safe settings

```bash
GRAPHIFY_BACKEND=none            # code-only; no LLM, no claude -p fallback
GRAPHIFY_QUERY_LOG_DISABLE=1     # forces query logging off (it is already off by default)
# Unset GEMINI_API_KEY and GOOGLE_API_KEY before using the /graphify skill,
# or skill mode will send docs to Google.
```

On mixed repos where docs must not leave the machine, keep `GRAPHIFY_BACKEND=none`. Upstream also mentions a `--code-only` flag for mixed repos; the research did not record which command takes it (probably `graphify extract . --code-only`; unverified, check `graphify --help`). Do not run `graphify install` or `graphify hook install` until you have read what they write (above).

## Conflicts/overlaps

- **`knowledge/` folder**: graphify is for navigation, not memory. Long-running memory lives in whichever of `knowledge/` (OKF), `DECISIONS.md` and `LOG.md` you kept. Do not treat the graph as a second source of truth.
- **LangExtract**: do not run both semantic passes over the same corpus. graphify is for relationships and navigation; LangExtract for auditable records.
- **Archify**: graphify shows the structure that exists; Archify draws the one you intended. They will disagree. Use the disagreement as a review input. Do not auto-sync one into the other.
- **Instruction files**: `graphify install` appends to `CLAUDE.md`. Keep it out of generated adapters (see above).
- **OKF knowledge files**: never promote `INFERRED` edges to OKF `verified` without human review.

See [guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md).

## Cost & risk

- Setup: one Python CLI. Light.
- Code-only graphs cost no LLM tokens.
- The semantic pass runs in parallel batches and can be costly on large doc or PDF corpora. The cache limits re-run cost.
- Risk: quiet changes to your setup if you run `install` or `hook install` (CLAUDE.md, git hooks, git config, `.gitattributes`).
- Risk: docs sent to Google in skill mode if a Google key happens to be set.
- Maturity: about 6.5 months old, very fast release churn. The installer takes the latest release unless you pass `--version`; record the version it prints in `SETUP_DECISIONS.md`.
- Upstream publishes self-reported benchmarks and a token-savings claim for its paid cloud. This kit does not cite or test them.

## Upstream link

<https://github.com/Graphify-Labs/graphify> (Apache-2.0; parts contributed before relicensing also remain under MIT)

## Checked: 2026-10-17

## Unverified

- The docs.graphify.com configuration page was not read.
- Which command takes the `--code-only` flag, and exactly what it skips.
- The full MCP tool list is not documented.
- Whether `AMBIGUOUS` edges are still emitted.
- The exact `GRAPHIFY_BACKEND` value for the OpenAI-compatible route (`openai` is assumed).
- The README's claim that the `claude` CLI works without an API key was not tested.
- LM Studio, vLLM and LiteLLM routes are named in code comments but untested by us.
