# Setup decisions

- Project: `<short name>`
- Date: `<YYYY-MM-DD>`
- Level: `<1 Starter | 2 Starter + tools | 3 Interview-led>`
- Interviewer model: `<model name and where it ran, e.g. "Claude in Claude Code", "qwen3 via Ollama">`
- Kit version: pmkit v0.1.0

<!-- Format: interview/OUTPUTS.md in the kit repo. Delete this comment when the file is filled in.

     SHORT FORM. If nothing beyond the minimal set was chosen (no tools, no knowledge/,
     no stages/), write 5 to 10 lines in all and delete the sections below. Example:

     # Setup decisions
     - Project: shop-site. Date: 2026-10-17. Level: 1. Interviewer: Claude in Claude Code. Kit: pmkit v0.1.0
     - Answers: a website; one-off; a few weeks; new; just me; Claude Code; minimal upkeep; no confidential data
     - Chosen: RULES.md, AGENTS.md, PROJECT.md, STATUS.md, CLAUDE.md that imports AGENTS.md (you use Claude Code, minimal upkeep). No tools.
     - Declined: DECISIONS.md, knowledge/, stages/ (minimal upkeep); LOG.md (code in git; git log covers it)
     - Revisit: if the same decision gets argued twice, add DECISIONS.md. Next look: 2026-11-14.

     FULL FORM. Use the sections below. Layer is exactly one of: Method, Tool, Service.
     Include "Installed tools" only if a tool was installed, and "Model routing" only if
     the data-sensitivity answer or a model choice changes where work runs.
     Otherwise delete those sections. Write answers and reasons in words, not
     question ids. Update this file whenever a tool is added or removed. -->

## Answers summary

| Question | Answer |
|---|---|
| What is being produced | `<answer>` |
| `<question>` | `<answer>` |

## Chosen

| Component | Layer | Why | Files created or changed | Revisit on |
|---|---|---|---|---|
| AGENTS.md, RULES.md | Method | Always | AGENTS.md, RULES.md | `<YYYY-MM-DD>` |
| `<component>` | `<Method / Tool / Service>` | `<short reason in words>` | `<paths>` | `<YYYY-MM-DD>` |

## Declined

| Component | Why not | Would reconsider if |
|---|---|---|
| `<component>` | `<short reason in words>` | `<trigger>` |

## Triggers to revisit

- If `<observable event>` → consider `<component>` (see the kit's `catalog/<card>.md`).

## Installed tools

| Tool | Version | Installed with | Privacy settings applied | Env example file |
|---|---|---|---|---|
| `<tool>` | `<exact version the installer printed>` | `<installer script and options, or manual step>` | `<e.g. ARCHIFY_UPDATE_CHECK_DISABLED=1>` | `.pmkit/env/<tool>.env.example` |

## Model routing

| Work | Model | Why |
|---|---|---|
| `<kind of work>` | `<model, and where it runs>` | `<data rule, cost, or quality reason>` |

## Disclaimer

This kit recommends third-party tools. It does not own or vouch for them. Read each tool card and the upstream README before installing. Check what leaves your machine. Security testing tools (e.g. Strix) may only be used on systems you own or have written permission to test. No warranty (MIT).
