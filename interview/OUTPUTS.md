# Interview outputs

Section titles start with the levels they apply to. "Level 2" means Level 2 and Level 3.

## All levels: what gets written

- **`SETUP_DECISIONS.md`** in the project root, every time except Level 3 "written plan only": what was chosen, why, what was declined, and when to look again.
- **`SETUP_PLAN.md`** only at Level 3 (Q17). **SETUP_PLAN rule:** "written plan only" writes `SETUP_PLAN.md` and nothing else; "plan and scaffold" writes `SETUP_DECISIONS.md` and the chosen files, and no `SETUP_PLAN.md`.

Rules: plain English, short sentences, no marketing words. Dates as `YYYY-MM-DD`; revisit dates are real dates or named milestones, not "later". Write answers and reasons in the user's words ("one-off", "just me"), not question ids; Level 3 may add ids in parentheses ("just me (Q05)"). Every chosen item gives its reason; every item considered and not chosen goes under "Declined" with a reason. Never write secrets, keys, tokens, private hostnames or personal data. What a card marks unverified stays "unverified". Layer names (full form only) are exactly `Method`, `Tool` or `Service`. Get a yes on the proposal before writing anything.

## All levels: short form of SETUP_DECISIONS.md

Use this when nothing beyond the minimal set (or the chat set) was chosen, and at Level 1 for any setup (list extra files on the "Chosen" line). 5 to 10 lines.

~~~~markdown
# Setup decisions

- Project: <short name> · Date: <YYYY-MM-DD> · Level: <1 | 2 | 3> · Kit: pmkit v0.1.0
- Interviewer model: <e.g. "Claude in Claude Code", "qwen3 via Ollama">
- Answers: <what it produces>; <one-off, repeated or ongoing>; <how long>; <new or existing material>; <just me or others>; <AI tool>; <upkeep>; <data rule> (one line, implied answers marked "implied")
- Chosen: <file list> — because <short reasons in words>
- Declined: <component> (<reason>); <component> (<reason>)
- Revisit on <YYYY-MM-DD>, or sooner if: <trigger>; <trigger>
- No tools installed.
~~~~

## All levels: full form of SETUP_DECISIONS.md

Use this when more than the minimal set was chosen. Keep these headings in this order; write "None." in an empty one. A blank version is `SETUP_DECISIONS.md` in the kit's template folder.

~~~~markdown
# Setup decisions

- Project: <short name>
- Date: <YYYY-MM-DD>
- Level: <1 Starter | 2 Starter + tools | 3 Interview-led>
- Interviewer model: <model name and where it ran>
- Kit version: pmkit v0.1.0

## Answers summary

| Question | Answer |
|---|---|
| What is being produced | <answer> |
| How the work runs over time | <answer, or "one-off (implied)"> |

## Chosen

| Component | Layer | Why | Files created or changed | Revisit on |
|---|---|---|---|---|
| AGENTS.md + CLAUDE.md import | Method | You use Claude Code | AGENTS.md, CLAUDE.md, .pmkit/ | <YYYY-MM-DD> |
| <component> | <Method / Tool / Service> | <short reason in words> | <paths> | <YYYY-MM-DD> |

## Declined

| Component | Why not | Would reconsider if |
|---|---|---|
| stages/ | One-off project | The same deliverable is made a 2nd time |

## Triggers to revisit

- If <observable event> → consider <component>.

## Disclaimer

This kit recommends third-party tools. It does not own or vouch for them. Read each tool card and the upstream README before installing. Check what leaves your machine. Security testing tools (e.g. Strix) may only be used on systems you own or have written permission to test. No warranty (MIT).
~~~~

Optional sections, added only when relevant (place them before "Disclaimer"):

- **Model routing** — only when Q08 restricts which models may see the content, or the user uses more than one model. One row per kind of work: `| Work | Model | Why |`. Never route project content to a cloud model the Q08 answer rules out. If quality may drop because of that, say so.
- **Installed tools** — only when a tool was actually installed (Level 2 and 3).

Field notes:

- **Revisit on** defaults to 4 weeks after setup for tools, and to the project's planned end (or 3 months) for files.
- If `LOG.md` is kept, append one `CREATE` entry listing the files created. Otherwise the setup is recorded here and in the first commit message.

## All levels: when the LLM cannot write files

After the yes and the `PROJECT.md` draft, print each file once, final and pruned, as a fenced code block with its path on the line above: `PROJECT.md`, the other kept files, then `SETUP_DECISIONS.md` (or `SETUP_PLAN.md`). Tell the user to save each block as a plain-text file with the name shown (ending in `.md`), or use the app's copy or download button. Keeping the files in a chat project: [../guides/chat-window.md](../guides/chat-window.md).

## All levels: SOURCES.md (browser chat, research)

One line per source, only sources the user has seen; never add one from memory.

~~~~markdown
# Sources

- <author or owner>, <title>, <year> — <where it is: link, file name or library> — <one line: what it is used for>
~~~~

## All levels: short example (nothing extra recommended)

A one-week solo script in git, minimal upkeep, Claude Code, Level 1.

~~~~markdown
# Setup decisions

- Project: csv-cleaner · Date: 2026-10-17 · Level: 1 · Kit: pmkit v0.1.0
- Interviewer model: Claude in Claude Code
- Answers: a code product; one-off; days; new; just me; Claude Code (implied); minimal upkeep; no confidential data, cloud is fine
- Chosen: AGENTS.md, RULES.md, PROJECT.md, STATUS.md, SETUP_DECISIONS.md, .gitignore, .pmkit/, CLAUDE.md import — because you chose minimal upkeep and use Claude Code
- Declined: LOG.md (code in git); DECISIONS.md (only days long); knowledge/ (minimal upkeep); stages/ (one-off)
- Revisit on 2026-10-24, or sooner if: the script becomes a repeated job; someone else will read the notes
- No tools installed.
~~~~

## Level 2: installed tools section

~~~~markdown
## Installed tools

| Tool | Version | Installed with | Privacy settings applied | Env example file |
|---|---|---|---|---|
| <tool> | <exact version the installer printed> | <installer script and flags, e.g. --version 1.2.3> | <e.g. ARCHIFY_UPDATE_CHECK_DISABLED=1> | .pmkit/env/<tool>.env.example |
~~~~

- List only what actually got installed. If an install was skipped or failed, move the tool to "Declined" with the reason.
- Record the exact version even when the latest was installed, so the setup can be repeated with `--version`.
- If `LOG.md` is kept, add one `TOOL-ADD` entry per installed tool.

## Level 3: written plan format (SETUP_PLAN.md)

Used only when Q17 = "written plan only". It is a plan the user can follow later or hand to someone else. It creates nothing else.

~~~~markdown
# Setup plan

- Project: <short name>
- Date: <YYYY-MM-DD>
- Level: 3 Interview-led (written plan only)
- Interviewer model: <model>
- Kit version: pmkit v0.1.0

## Summary

<3 to 5 sentences: what the project is, the upkeep level the user chose (Q07), and the overall shape of the setup.>

## Answers summary

| Question (id) | Answer |
|---|---|

## Use now

Only items whose trigger holds now.

| Component | Layer | Why | What it adds or changes | How to set it up |
|---|---|---|---|---|
| <component> | <Method / Tool / Service> | <reason in words, id in parentheses> | <files, settings, network calls> | <copy template file / installer script and --version / manual steps from the card> |

## Do not use (and why)

| Component | Why not |
|---|---|

## Add later, on a trigger

Things needed only at a handoff or milestone (for example a curated diagram, an `ocr scan` before handoff) go here with their date or milestone.

| If this happens, or by this date | Consider | Check first |
|---|---|---|
| <observable event or YYYY-MM-DD / milestone> | <component> | <card link, conflicts to check> |

## Service-layer tools (manual, with warnings)

For each Service-layer tool in "Use now" or "Add later": what it runs (services, Docker, databases), what leaves the machine, telemetry and how to turn it off, keys needed (names only, never values), spend cap, and the authorisation rule for security testing. "None." if there are none.

## Your own tools

For each tool from Q16: the filled card fields (see catalog/_card-template.md), overlap with the choices above, warnings, and this note: "Not reviewed by this kit. Unverified. You decide."

## Model routing

Only if Q08 restricts models or more than one model is used. Otherwise "None."

| Work | Model | Why |
|---|---|---|

## Bloat check

- Files the plan adds: <count and list>
- Tools the plan installs now: <count and list>
- What the user said they will maintain (Q07): <answer>
- Anything above that cap: <none, or what to cut>

## First three steps

1. <step>
2. <step>
3. <step>

## Disclaimer

This kit recommends third-party tools. It does not own or vouch for them. Read each tool card and the upstream README before installing. Check what leaves your machine. Security testing tools (e.g. Strix) may only be used on systems you own or have written permission to test. No warranty (MIT).
~~~~

If the user later wants the scaffold, the plan's "Use now" table becomes the "Chosen" table of `SETUP_DECISIONS.md`, and `SETUP_PLAN.md` can be deleted or kept as history.
