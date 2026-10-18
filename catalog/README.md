# Tool catalog

One card per method or tool. Each card says what it does, what it does not do, when to add it, what it touches on your machine and what leaves it.

Before installing anything, please read the [disclaimer in the README](../README.md).

## How to use it

- **Start with methods.** They are file conventions with nothing to install.
- **Add a tool only when a trigger on its card holds now.** Anything you will only need later (for example a diagram or a repo scan at handoff) goes under "Add later" in `SETUP_DECISIONS.md`, with a date or milestone.
- **Log each tool decision** with its trigger and a revisit date, and remove tools that did not pay off. See [guides/adding-tools-mid-project.md](../guides/adding-tools-mid-project.md).

## Layers

Layers describe tools. They are a different scale from Levels 1, 2 and 3, which describe how much setup you choose.

| Layer | Meaning |
|---|---|
| **Method** | File conventions. Nothing to install. |
| **Tool** | Local install. Writes files. No service running in the background. |
| **Service** | Database, Docker, API keys, network access, or active risk. |

## Cards

| Card | Layer | What for | Phase fit | Needs API key? | Local-model route? | Level available |
|---|---|---|---|---|---|---|
| [ICM + icm-template](icm.md) | Method | Numbered stages with short contracts for repeatable work | kickoff, planning, build, review, docs, handoff | No | Through your agent; paste `AGENTS.md` + stage file into any model | Level 1, 2, 3 |
| [OKF v0.2](okf.md) | Method (reference agent: Service, out of scope) | The `knowledge/` folder: readable notes shared by you and the LLM, with trust and staleness fields | kickoff, research, docs, handoff, maintenance | No (reference agent: Gemini) | Spec: any model. Reference agent: not supported | Level 1, 2, 3 |
| [Procedural Graphs pattern](procedural-graphs.md) | Method | Pitfalls on stage handoffs, grown from repeated failures | planning, build, maintenance, research | No | Any model reads the file; not evaluated in the paper | Level 1, 2, 3 |
| [Archify](archify.md) | Tool | Checked, shareable HTML diagrams for review now, or added later for handoff | planning, docs, review, handoff | No | Inherits your agent's model; small models untested | Level 2, 3 |
| [graphify](graphify.md) | Tool (code-only); Service with cloud backend | Graph of an existing codebase for navigation | kickoff, research, build, review, handoff, maintenance | Code-only: no. Semantic pass: yes, unless local | Headless CLI: `GRAPHIFY_BACKEND=ollama`. The `/graphify` skill is not local-safe | Level 2 (code-only), Level 3 |
| [Open Code Review](open-code-review.md) | Tool (delegation mode); Service with own LLM | LLM review of git diffs (code in git only) | build, review, maintenance | Delegation mode: no. Default mode: yes | Delegation via a local host agent, or Ollama as a custom provider; model must support tool calls | Level 2, 3 |
| [LangExtract](langextract.md) | Tool (with local model); Service with cloud model | Turning a pile of text into records with source spans | research, build, docs | Gemini/OpenAI: yes. Ollama: no | Ollama via `model_url` or `OLLAMA_BASE_URL` (no `/v1`) | Level 2, 3 |
| [Strix](strix.md) | Service | Autonomous security testing of systems you own | security, review | Yes, unless local | LiteLLM route; docs say models under 70B struggle | Level 3 only (manual, with warnings) |
| [workflow-graph](workflow-graph.md) (fallback) | Tool | Live DAG status inside an existing web UI. Fallback to Archify | build, docs | No | Not applicable | Level 3 only |

Level available: **Level 1** = Starter (methods only, no installs). **Level 2** = Starter + tools (light tools through installers that ask before every step). **Level 3** = Interview-led (everything; Service-layer tools as manual guided steps).

## Defaults worth knowing before you install anything

- **Mermaid in markdown** is the default for diagrams. Archify comes after.
- **Plain markdown** is the default for project memory: `STATUS.md`, plus `DECISIONS.md` and a `knowledge/` folder with OKF frontmatter if you chose them. `LOG.md` is optional; for code in git, `git log` already covers actions. graphify comes after, for code and doc navigation.
- **Open Code Review in delegation mode** adds no extra key or cost. Its default mode silently reuses `ANTHROPIC_*` env vars if nothing else is set.
- **graphify skill mode** sends docs to Gemini if `GEMINI_API_KEY` or `GOOGLE_API_KEY` is set, whatever `GRAPHIFY_BACKEND` says.
- **Strix** attacks its target. Only use it on systems you own or have written permission to test, with `--max-budget` set.

More detail:

- Rules for overlaps and conflicts: [guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md)
- Network and file-touch table for every tool: [guides/privacy-and-network.md](../guides/privacy-and-network.md)
- Local models: [guides/local-models.md](../guides/local-models.md)

## Tools not in this catalog

Copy [_card-template.md](_card-template.md) and follow [guides/bring-your-own-tool.md](../guides/bring-your-own-tool.md). The LLM fills in the card, checks it against the overlaps above, warns you about conflicts and adds a disclaimer. You decide.

## Dates and versions

- Every card shows the date its facts were checked. All cards here were checked on 2026-10-17. Several of these tools release every few days.
- The Level 2 installers install the latest release by default and print the exact version installed. To pin one, pass `--version <v>` (`-Version <v>` in PowerShell).
- Archify cannot be pinned: its installer only checks the installed version and stops if it differs.
- Either way, please record the installed version in `SETUP_DECISIONS.md` under "Installed tools".
