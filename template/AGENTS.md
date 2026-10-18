# Agent instructions: `<fill in project name>`

Read RULES.md before anything else, every session. It holds the working rules. This file holds the mechanics: what to read for a task and how to keep the project files.

Edit AGENTS.md and RULES.md directly.
Copies such as CLAUDE.md, if this project uses any, are generated from AGENTS.md by `python .pmkit/pmkit.py sync`. <!-- needs: .pmkit/ -->
If a tool adds lines to CLAUDE.md (Claude Code's `/init` does, and `#` memory in versions that have it), move them into this file so every agent sees them.

`<fill in: one or two sentences on what this project is.>`

## What to read, by task

Read only what the task needs. Do not load every file at the start of a session.

<!-- Write each path in backticks or as a link. pmkit check treats only those as routes. -->

| Task | Read |
|---|---|
| Every session, first | `RULES.md`, then `STATUS.md` |
| Scope or priority question | `PROJECT.md` |
| "Why is it like this?" | `DECISIONS.md` <!-- needs: DECISIONS.md --> |
| Background, glossary, domain facts | `knowledge/index.md`, then only the linked files you need <!-- needs: knowledge/ --> |
| Work inside a stage | `stages/NN-name/CONTEXT.md` for that stage only <!-- needs: stages/ --> |
| Adding, changing or removing a tool or service | `SETUP_DECISIONS.md` <!-- needs: SETUP_DECISIONS.md --> |
| `<fill in task, or delete this row>` | `<fill in file>` |

## Keeping the files

- At the end of a session, overwrite STATUS.md: now, next, blocked, date.
- Append one line to LOG.md for each meaningful action, including each tool added or removed (types: CREATE, UPDATE, DECIDE, TOOL-ADD, TOOL-REMOVE, REVIEW, HANDOFF). Never edit or delete old lines. <!-- needs: LOG.md -->
- Record decisions in DECISIONS.md as the next D-### entry. Never rewrite old ones; add a new entry that supersedes. <!-- needs: DECISIONS.md -->
- Files under knowledge/ need frontmatter with at least `type`. When you write one, set `generated: {by, at}`. Never add yourself to `verified`; only a person verifies. <!-- needs: knowledge/ -->
- New tools and services (an AI tool, an MCP server, a hosted service, anything from the kit's catalog) need a concrete trigger. Propose one first. If the person agrees, record it in SETUP_DECISIONS.md with a revisit date, and record it there again when it is removed. Ordinary libraries and packages the code needs are not covered by this rule; follow the project's usual practice for those. <!-- needs: SETUP_DECISIONS.md -->

## Project-specific rules

<!-- Keep this to a few lines, or delete the section. If the project holds personal or
     confidential data, add a rule such as: "Do not send project files to any cloud AI
     service except <the approved one, or none>." -->

- `<fill in, or delete this section>`

## Checks <!-- needs: .pmkit/ -->

Run `python .pmkit/pmkit.py check` before a handoff and after editing this file. If adapters are enabled, run `python .pmkit/pmkit.py sync` first.
