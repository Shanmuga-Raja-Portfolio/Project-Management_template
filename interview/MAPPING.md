# Answer to recommendation rules

These rules turn answers ([QUESTIONS.md](QUESTIONS.md)) into a setup. Every chosen item gives the answer it rests on; every item considered and not chosen goes in "Declined" with a reason. Section titles start with "All levels" or "Level N" (N and higher). If a tool card and a rule disagree, the card wins (report it as a bug).

## All levels: order of application

Level gate (Level 1: files only; Level 2: plus light tools, each with a yes; Level 3: Service-layer tools as manual steps with warnings) → existing conventions → upkeep cap (Q07), which nothing after may exceed, tools included → **Method layer** (template files) → **Tool** (Level 2+) and **Service layer** (Level 3) only if a trigger holds *now*; later needs become dated triggers → privacy (Q08), plus budget at Level 2+ → conflicts → prune → **prefer less**.

## All levels: existing conventions

Before proposing files, look for these and reuse them; do not duplicate. Browser chat only (Q06): skip this section.

- Decision records (`docs/adr/` or similar) → no `DECISIONS.md`; point the AGENTS.md "Why is it like this?" row there.
- `CONTRIBUTING.md` → link it from AGENTS.md "Project-specific rules"; do not copy it.
- An existing `AGENTS.md` → do not overwrite; offer to merge the missing kit rules.
- A hand-written `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.cursor/rules/` or `.github/copilot-instructions.md` → no adapter over it; offer to move its content into `AGENTS.md`.
- `README.md`, `.gitignore` → never overwrite; for `.gitignore`, show the lines to add.
- A `.git` folder (code) → `LOG.md` is optional. CI review bots → they are the review step. An issue tracker → `STATUS.md` holds only the session handoff and links it.

## All levels: upkeep cap (Q07) and files (Method layer)

| Q07 | Maximum file set |
|---|---|
| minimal | `AGENTS.md`, `RULES.md`, `PROJECT.md`, `STATUS.md`, `SETUP_DECISIONS.md`, `.gitignore` (rule below), `.pmkit/` (if Python), `LOG.md` (rule below) |
| + decision log / + knowledge folder | minimal + `DECISIONS.md` / + `knowledge/` |
| both | minimal + `DECISIONS.md` + `knowledge/` |
| full | both + `stages/` |

**Tools count as upkeep.** Q07 = minimal: no tool now, even if its trigger holds (it goes under "Triggers to revisit") unless the user names it.

**Browser chat window only (Q06):** `PROJECT.md`, `STATUS.md`, `RULES.md` (General and Documentation sections only), a short `SETUP_DECISIONS.md`. Nothing else. **This set wins over the file rules below.** Research or data in a chat: offer one `SOURCES.md` ([OUTPUTS.md](OUTPUTS.md)) and list `knowledge/` under "Declined". Each session the user pastes `RULES.md` and `STATUS.md` ([../guides/chat-window.md](../guides/chat-window.md)).

Within the cap, keep a file only when its rule holds:

- `AGENTS.md`, `RULES.md`, `PROJECT.md`, `STATUS.md`, `SETUP_DECISIONS.md`: always (chat window only: rule above).
- `RULES.md`: copy as is; delete whole sections only, never reword or renumber rules. Chat window only (Q06): delete "## Agent" and "## Code"; not code (Q01): delete "## Code".
- `LOG.md`: unless the project is code in git (then only if the user wants it).
- `DECISIONS.md`: Q03 = weeks+, Q02 = ongoing product, or Q05 = team/handoff.
- `knowledge/`: Q05 = team/handoff, Q03 = months+, or Q01 = research/data (research: fill `sources` per concept).
- `stages/`: Q02 = repeatable process or recurring intake. Keep `Pitfalls` empty until a stage fails the same way twice.
- `.pmkit/`: the user works in a folder and has Python 3.8+. Without Python, prune by hand and note that `check` cannot run.
- `.gitignore`: code or git, and none exists. `template/README.md`: read once, outside the cap; skip it if the project has a README.
- Q04 = existing: add files next to existing material, move or rename nothing, note in `PROJECT.md` where it lives.

**Pruning rule:** keep the structure of the files you keep (`RULES.md`: only the section rule above), but remove routing rows, rules and links that point to files you dropped (run pmkit prune if .pmkit is present). Lines that depend on optional files end with `<!-- needs: PATH -->`; `python .pmkit/pmkit.py prune --dry-run` previews removals.

## All levels: adapters (Q06)

Only `AGENTS.md` is edited. `.pmkit/adapters.txt` ships with nothing enabled; enable a line (`<path> [import|copy]`, default `copy`) only for a Q06 tool that needs it, then run `python .pmkit/pmkit.py sync`. No enabled line: do not run `sync`.

- Claude Code → `CLAUDE.md import` (a header plus `@AGENTS.md`; Claude Code reads `@path` imports). No Python: write `CLAUDE.md` by hand as the line `@AGENTS.md`. Lines Claude Code adds to `CLAUDE.md` (`/init`, or `#` memory where available) belong in `AGENTS.md`; `check` warns.
- Codex, Cursor, OpenCode, GitHub Copilot coding agent and other agents that read `AGENTS.md` natively → no adapter (checked 2026-10-17; verify for your version). Cursor's `.cursor/rules/` is optional; do not use legacy `.cursorrules`.
- Gemini CLI → `GEMINI.md copy`, or set its context file name to `AGENTS.md`.
- Aider → no adapter; load `AGENTS.md` as a read-only file each session (unverified; check Aider's docs).
- A tool that reads only its own file → `<that path> copy`. A local model in a chat app → paste `AGENTS.md`, `RULES.md` and `STATUS.md` at session start.

## All levels: privacy (Q08)

- Cloud is fine → nothing extra.
- Rules go in AGENTS.md "Project-specific rules" (browser chat: under "Constraints" in `PROJECT.md`).
- Approved enterprise vendor only → rule: "Use only `<approved vendor/model>` for this project's content."
- Nothing may leave, or not sure → rule: "Do not send this project's content to any cloud AI service; use only a local model." "Not sure" also gets a trigger to update the rule once checked.
- Fill the Data line in `PROJECT.md`. Never route project work to a cloud model unless Q08 allows it. Add "Model routing" to `SETUP_DECISIONS.md` only when Q08 restricts models or more than one model is used.

## All levels: conflicts, nothing extra, triggers

- **One instruction file** (`AGENTS.md`) and **one record of truth**: each fact lives in one place (`knowledge/`, `DECISIONS.md`, `LOG.md` or git history).
- **Recommending nothing extra is a normal result:** one-off + days + solo, or Q07 = minimal → the minimal set and short-form `SETUP_DECISIONS.md`.
- **Triggers** (each with a date or milestone): same deliverable made a 2nd time → `stages/`; someone else reads the notes, or a stale note misled the agent → `knowledge/`; a stage fails the same way twice → a pitfall; you cannot recall why something was done → `DECISIONS.md`; a second person joins → revisit Q05; the chat window is not enough → rerun with an agent on a folder. Agent users, mid-project: [../guides/adding-tools-mid-project.md](../guides/adding-tools-mid-project.md).

## Level 1: files only

- Short-form `SETUP_DECISIONS.md`. If a need seems to call for a tool (a very large codebase, hundreds of documents, a security test), name no tool; add the trigger "consider rerunning the interview at Level 2 or 3".

## Level 2: extra answers

These answers are asked from Level 2 on and adjust the file rules above.

| Answer | Effect |
|---|---|
| Q11 = made things up or forgot context | `knowledge/` is a strong fit, within the cap. |
| Q11 = agents on the team diverged | Check every agent named in Q06 reads `AGENTS.md` (adapters above); add a decision log, within the cap. |
| Q04 follow-up: existing code not in git | No code review tool. Trigger: "when the code goes into git". |

## Level 2: tool layer (light tools)

Add a tool only when its trigger holds now. Each added tool gets a revisit date (default: 4 weeks from today) in `SETUP_DECISIONS.md`, and a `TOOL-ADD` entry if `LOG.md` is kept. Something needed only at a later handoff or milestone goes under "Add later" or triggers with that date, not into day one.

| Tool | Recommend now when | Do not recommend when | Card |
|---|---|---|---|
| **Open Code Review**, delegation mode | Q01 = code AND the code is in git, AND one of: PRs or merges on shared code now; Q11 = missed bugs | No git, or no code; solo throwaway prototype; a CI review bot already covers it; Q04 = inherited alone (`ocr scan`: rule below) | [open-code-review](../catalog/open-code-review.md) |
| **graphify**, code-only (`GRAPHIFY_BACKEND=none`) | Q04 = existing and large, or inherited (code); or Q11 = forgot context and the agent re-reads or greps the same files each session | Q04 = new, or existing and small; no code | [graphify](../catalog/graphify.md) |
| **LangExtract** | Q10 = a folder or hundreds of files *and* the user needs checkable records with source spans; or Q11 = made things up on extraction work | Little text; the job is Q&A or search; Q08 = nothing may leave and no local model (Q09) | [langextract](../catalog/langextract.md) |
| **Archify** | A named audience needs an architecture or workflow picture *now* that Mermaid cannot make clear (at Level 3: Q15 = curated diagram, needed now) | Nobody will read it; Mermaid is enough; needed only at a later handoff (add a trigger with that date) | [archify](../catalog/archify.md) |

Set each chosen tool up as its card's "Install" and "Privacy-safe settings" say. Points to tell the user before the yes:

- **Open Code Review:** delegation mode first (no LLM call on the OCR side, no extra key). Without a configured provider OCR silently reuses `ANTHROPIC_*` env vars.
- **`ocr scan` of an inherited repo:** always "Add later", with a date or milestone. Warn that it reviews whole files, so a large repo costs many tokens; scan one folder at a time (`--path <dir>`).
- **graphify:** `graphify install` and `graphify hook install` write outside the project (assistant config, git hooks, git config, `.gitattributes`) and need their own yes. The `/graphify` skill ignores `GRAPHIFY_BACKEND` and uses Gemini if `GEMINI_API_KEY` or `GOOGLE_API_KEY` is set.
- **LangExtract:** core install pulls `google-genai` and `google-cloud-storage` even for Ollama-only use.
- **Archify:** set `ARCHIFY_UPDATE_CHECK_DISABLED=1` to stop its only outbound request.

## Level 2: privacy and budget filters for tools

Apply after choosing. These remove or reconfigure tools.

| Answer | Effect |
|---|---|
| Q08 = nothing may leave, or not sure | Local model server required for any tool that calls an LLM. graphify code-only or headless Ollama only (the `/graphify` skill is not local-safe). OCR delegation with a host agent on a local model. `ARCHIFY_UPDATE_CHECK_DISABLED=1`. |
| Q08 = approved enterprise vendor only | Only tools that can point at that vendor's endpoint, or that make no LLM call (OCR delegation with a host agent on the approved vendor, graphify code-only, Archify). If a card does not document the vendor, decline the tool as "unverified for your vendor". |
| Q08 = code may leave, docs may not | graphify code-only; no semantic pass on docs. LangExtract only with a local model. |
| Q09 budget = none | Methods only, OCR delegation, graphify code-only, local Ollama. Tools needing tool calls want roughly 30B+ models. |
| Q09 budget = small cap | Avoid multi-pass LangExtract over large corpora. |
| Q09 subscription fallback = not OK | Turn off `claude -p` fallbacks: `GRAPHIFY_BACKEND=none`. |
| Q09 hardware = no | No local-model route; decline local-only choices with this reason. |

See [../guides/privacy-and-network.md](../guides/privacy-and-network.md) and [../guides/local-models.md](../guides/local-models.md).

## Level 2: tool conflicts

Each card's "Conflicts/overlaps" section has the details; full rules: [../guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md). In short: graphify registration never edits `AGENTS.md` silently; graphify navigates, it is not a second memory; one extractor per corpus (LangExtract or the graphify semantic pass); Open Code Review per PR, not per save; graphify INFERRED edges and LangExtract records never become `verified` without human review; graphify (what exists) and Archify (what was intended) are compared by a person, never auto-synced.

## Level 2: recommend nothing extra and triggers (tools)

- Q04 = new, Q10 = little, Q11 = nothing yet → no installers; Level 2 can end with zero tools.
- Q08 = nothing may leave, Q09 = no budget and no hardware → files only, plus graphify code-only and OCR delegation if their triggers hold.
- Triggers: the agent re-reads the same files every session, or the codebase outgrows your head → graphify code-only. First PRs on shared code → Open Code Review delegation, if the code is in git. An inherited repo or a handoff date → `ocr scan` under "Add later" (rule above). A pile of text must become checkable records → LangExtract. A handoff or meeting on a known date needs a picture Mermaid cannot make clear → Archify, before that date.

## Level 3: order and outputs

- Ask Q17 (plan only, or scaffold) first.
- **SETUP_PLAN rule:** "written plan only" writes `SETUP_PLAN.md` and nothing else; "plan and scaffold" writes `SETUP_DECISIONS.md` and the chosen files, and no `SETUP_PLAN.md`.
- Q13 = tests, rubric or metric: allows stage audits and a "keep a change only if not worse" rule. Q13 = not defined: add a human review checkpoint and rule out any automated self-improvement. Put the answer in `PROJECT.md` "Done when".
- Q14 = yes: add glossary concepts in `knowledge/` (this keeps `knowledge/` even if other rules would drop it, still within the cap) and add this to the end of `PROJECT.md`: the heading `## Onboarding`, a blank line, and the line "New here? Read this file, then STATUS.md, then knowledge/index.md and the glossary concepts it links." Q14 = no, or not asked: add nothing.
- Q15 = curated diagram needed now → Archify (Tool layer). Needed at a later handoff → "Add later" with that date.

## Level 3: service layer

Never installed by a Level 2 installer. At Level 3 they appear as manual steps with warnings, and only after an explicit privacy and budget check: Q08 = nothing may leave or not sure → no Strix Cloud; Q09 = small cap → set `--max-budget` on Strix. Run Strix nightly or before release, not on every PR.

| Tool | Recommend when | Never when | Card |
|---|---|---|---|
| **Strix** | Q12 = owned or authorised in writing, a web app or API is about to be exposed (staging or pre-release), Docker is available, and a spend cap is set (`--max-budget`) | Q12 = not authorised or not sure; production or third-party targets; no attack surface | [strix](../catalog/strix.md) |
| **graphify semantic pass** | Cross-links between docs, specs and code are needed now, and a local model or an approved cloud provider is configured | Q08 = docs may not leave and no local model | [graphify](../catalog/graphify.md) |
| **Open Code Review with its own LLM or in CI** | Code in git, Q05 = team with a PR flow now, where reviews must be repeatable and not tied to one person's agent | Solo prototype; a CI review bot already covers it | [open-code-review](../catalog/open-code-review.md) |
| **workflow-graph** (fallback) | Q15 = existing web UI that must show live DAG status | Any other case. It renders DAGs only, does not run workflows, and npm is at a stale 0.1.2 | [workflow-graph](../catalog/workflow-graph.md) |
| **Bring-your-own tool** | Q16 names a tool | Evaluate with [bring-your-own-tool](../guides/bring-your-own-tool.md); the user decides | [_card-template](../catalog/_card-template.md) |

## Level 3: recommend nothing extra and triggers

- No Q12 surface and Q15 = no → no Service-layer tools. The plan lists them only as triggers, if at all.
- A Q16 tool overlaps a chosen tool → recommend one of the two, or neither. The user decides.
- A web app or API you own is about to be exposed → consider Strix (written permission, spend cap).
- New people must learn a large, stable body of facts → glossary concepts in `knowledge/` and the Onboarding section in `PROJECT.md` (text in the Q14 rule); an Archify diagram before the handoff date if a picture is needed.
