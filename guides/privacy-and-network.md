# Privacy and network

What each tool sends off your machine, what it writes to disk, and the settings that keep it quiet. Please read this before installing anything.

Facts here come from the kit's research, checked 2026-10-17. Defaults in these tools change often, sometimes weekly. The installers take the latest release unless you pass `--version <v>` (PowerShell `-Version <v>`); record the version they print in `SETUP_DECISIONS.md`, and re-check before relying on this page. Layers (Method, Tool, Service) are defined in the [catalog README](../catalog/README.md#layers).

## Before any tool: your agent and your data

The biggest data flow is usually your agent sending what it reads to its model, not a tool. So first answer the interview's data question: does the project include personal or confidential data, and may it go to a cloud AI service?

- **Yes, cloud is fine:** use your agent as usual.
- **Only an approved enterprise vendor** (for example Azure, Bedrock or Vertex): point the agent and every tool at that endpoint only. A tool that falls back to another provider when not configured (see the table) is a leak.
- **No, it must stay local:** run the agent on a local model (see [local-models.md](local-models.md)) and use only the local routes below. Also write it as a rule: in `RULES.md` for an agent setup, or in the "Constraints" section of `PROJECT.md` for a chat-window setup. That rule is a request to the model, not a guarantee.

## The kit itself

The kit's own files (the template, `.pmkit/pmkit.py`, the scripts) make no network calls. The Level 2 installers call out only to download the tool you approve (npm registry, PyPI, and GitHub for the Archify skill), and print those calls before running them.

## Summary table

| Tool | Layer | Data leaving the machine (default) | Telemetry | Files and settings it touches |
| --- | --- | --- | --- | --- |
| ICM, OKF spec, Procedural-Graphs pitfalls | Method | None of their own. Your agent sends what it reads to its model | None | Only the files you create |
| Archify | Tool | One update-check GET to a fixed manifest on `tt-a1i.github.io` (no project data; the server sees your IP and time). Generated HTML may contain external links | None found beyond the update check | Skill folder (e.g. `~/.claude/skills/` or `.claude/skills/`); output HTML files; reminder state (unless disabled) |
| graphify, code-only | Tool | None, if `GRAPHIFY_BACKEND=none`. Without it, community labelling can send code symbol names to an LLM, including a `claude -p` fallback | None found in code | `graphify-out/` (`graph.json`, `GRAPH_REPORT.md`, `graph.html`) |
| graphify, semantic pass | Tool / Service | Docs, PDFs and images go to the configured LLM. In skill mode: Gemini if `GEMINI_API_KEY`/`GOOGLE_API_KEY` is set, else the host model | None found in code | As above, plus `~/.graphify/providers.json` if you add providers |
| graphify `install` | Tool | - | - | `~/.claude/skills/graphify/`, appends to `~/.claude/CLAUDE.md`, lock file under `~/.cache/graphify/skill-locks/`. Per-platform installs add hooks in agent settings |
| graphify `hook install` | Tool | - | - | 4 git hooks (post-commit, post-checkout, post-merge, post-rewrite), git config `merge.graphify.*`, `.gitattributes` |
| Open Code Review, delegation | Tool | None from OCR. Your host agent does the review with its own model | Off by default | Claude Code plugin commands, if you install the plugin |
| Open Code Review, own LLM | Service | Diffs and file contents go to the configured provider. Many presets are hosted in China. Falls back to `ANTHROPIC_*` env vars if not configured | Off by default (opt-in `OCR_ENABLE_TELEMETRY=1`; no built-in remote endpoint) | `~/.opencodereview/config.json` |
| LangExtract | Tool / Service | With Gemini or OpenAI: your documents. With local Ollama: none | Not documented | Output files you choose (JSONL, review HTML). Core install pulls `google-genai` and `google-cloud-storage` |
| Strix | Service | Code, target responses and findings go to the LLM provider. Credentials you put in `--instruction` go to the LLM. **It actively attacks the target.** Strix Cloud uploads your source | Not documented | `~/.strix/cli-config.json`, `strix_runs/`, optional `~/.strix/mcp-servers.json`; runs Docker containers |
| workflow-graph | Tool | No runtime network calls documented (client-side renderer) | None | Your web app's dependencies |
| OKF reference agent | Service | Dataset metadata and fetched web pages to Google (Gemini). BigQuery query bytes are billed to your project | Not documented | `./bundles/<name>/` |

"Not documented" means the research found no statement either way. Treat it as unverified.

## Privacy-safe settings per tool

The Level 2 installers write these to `./.pmkit/env/<tool>.env.example` in your project. They never write a real `.env` and never write keys. Copy the values into your own shell or secret store.

### Archify

```sh
ARCHIFY_UPDATE_CHECK_DISABLED=1   # stops the only outbound request and the reminder-state writes
```

Archify's README lists discounted API reseller and relay services as sponsors. Archify does not need them; do not route keys through them.

### graphify

```sh
GRAPHIFY_BACKEND=none             # code-only: no LLM, no claude -p labelling fallback
GRAPHIFY_QUERY_LOG_DISABLE=1      # forces query logging off (code says it is already off by default; README says on)
# Unset these before running graphify, or skill mode sends docs to Gemini:
#   GEMINI_API_KEY
#   GOOGLE_API_KEY
```

- Run `graphify install` or `graphify hook install` only if you want the file changes listed above. The installer asks separately for each.
- The `/graphify` skill ignores `GRAPHIFY_BACKEND`. For local-only semantic passes, use the headless CLI with Ollama (see [local-models.md](local-models.md)) and a `localhost` URL.
- Install the exact PyPI name `graphifyy` (two y's).

### Open Code Review

```sh
# Use delegation mode: no OCR-side key, no OCR-side LLM call.
# Leave these unset:
#   OCR_ENABLE_TELEMETRY
#   OCR_CONTENT_LOGGING
# If you use own-LLM mode, write ~/.opencodereview/config.json explicitly,
# so OCR does not fall back to ANTHROPIC_BASE_URL / ANTHROPIC_AUTH_TOKEN / ANTHROPIC_MODEL.
```

Choose a provider on purpose; many presets are hosted in China.

### LangExtract

```sh
OLLAMA_BASE_URL=http://localhost:11434   # local Ollama, no /v1
# Do not set GEMINI_API_KEY, LANGEXTRACT_API_KEY or OPENAI_API_KEY
# for projects whose text must stay local.
```

Set `OLLAMA_BASE_URL` for this tool only; graphify reads the same variable but wants `/v1`. For health-related use, LangExtract also falls under the Health AI Developer Foundations terms.

### Strix (Level 3 only, Service layer)

```sh
STRIX_LLM=ollama/<model>
LLM_API_BASE=http://localhost:11434
# Always pass --max-budget <USD> when using a paid model. Without it there is no limit.
```

- Only test systems you own or have written permission to test. Never production. Never third parties.
- Do not use Strix Cloud for code that must stay local; it uploads your source.
- Do not put real credentials in `--instruction` unless you accept that the LLM provider sees them.
- The `strix view` link carries a token. Share it carefully.

### workflow-graph (fallback)

No settings needed: no model, no documented runtime network calls.

## Questions to ask about any tool

For tools not listed here (see [bring-your-own-tool.md](bring-your-own-tool.md)):

1. What does it send, and to whom, with default settings?
2. Is telemetry on by default? What turns it off?
3. Which env vars does it read? Could it pick up a key you set for something else?
4. Does it fall back to a paid service or your subscription when not configured?
5. Which files, hooks, git settings and agent settings does it change?
6. Does it run a server? On which port, with which default password?
7. Does it download large models or binaries on first use?
8. Can it act on systems beyond your machine (attack, deploy, delete)?

## Untrusted content

Papers, web pages and READMEs that an agent reads are data, not instructions. During the kit's research, one fetch of an arXiv paper reported embedded instructions aimed at AI summarisers. If fetched content tells the agent to run something, change settings or send data, the agent shows it to you and does not act on it.
