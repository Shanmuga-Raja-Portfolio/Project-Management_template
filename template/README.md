# Project folder (guide to the pmkit files)

This page explains the files pmkit set up for you. It is not a project file, so please delete it once you know what each file is for. If your project already had a README.md, this guide was not copied; you can read it [in the kit repo](https://github.com/Shanmuga-Raja-Portfolio/Project-Management_template/blob/main/template/README.md).

Everything here is plain markdown plus one optional script. Nothing runs on its own.

## Getting started

- Replace the placeholders: text in angle brackets that starts with "fill in".
- Delete what you do not need. A file nobody updates is worse than no file.

## Files

| File | What it is for | Delete it when |
|---|---|---|
| [AGENTS.md](AGENTS.md) | The instruction file for any AI agent: what to read for each task, and how to keep these files. Edit this one, not the copies. <!-- needs: AGENTS.md --> | Never. Keep it short instead. |
| [RULES.md](RULES.md) | Working rules in four sections. General and Documentation apply to everyone. Agent applies when an agent works on your files; delete it if you only use a chat window. Code applies to new code; delete it for a non-code project. AGENTS.md tells the agent to read it first, every session. Edit it freely. <!-- needs: RULES.md --> | Never. Cut it down instead. |
| [PROJECT.md](PROJECT.md) | Goal, users, scope, done criteria, constraints, risks. | Never. |
| [STATUS.md](STATUS.md) | Where things stand now. Overwritten each session. | Never. |
| [SETUP_DECISIONS.md](SETUP_DECISIONS.md) | What the setup interview chose, what it declined, and why. Often only 5 to 10 lines. <!-- needs: SETUP_DECISIONS.md --> | Never. Update it when you add or remove a tool. |
| [DECISIONS.md](DECISIONS.md) | Append-only list of decisions (D-001, D-002, ...). <!-- needs: DECISIONS.md --> | A short task with no real decisions. |
| [LOG.md](LOG.md) | Append-only work log with action types. <!-- needs: LOG.md --> | Code kept in git, where the commit history covers it. |
| [knowledge/](knowledge/index.md) | Lasting knowledge (decisions in depth, glossary, data and system notes) in OKF v0.2 format. <!-- needs: knowledge/ --> | The project is short, solo, and nobody else will read the notes. |
| [stages/](stages/README.md) | Optional numbered stages for a process you run more than once. <!-- needs: stages/ --> | The project is a one-off. Delete the whole folder. |
| `.gitignore` | Keeps local environments and `.env` files out of git. Only copied if the project had none. <!-- needs: .gitignore --> | You do not use git. |
| `.pmkit/adapters.txt` | Which tool-specific copies of AGENTS.md to write. Nothing is enabled by default. <!-- needs: .pmkit/ --> | Your agents all read AGENTS.md directly. |
| `.pmkit/pmkit.py` | Helper script: prune, check, sync, log, decide. <!-- needs: .pmkit/ --> | You never run it. Nothing breaks without it. |

## Markers you will see

Some lines end with a comment such as `<!-- needs: DECISIONS.md -->`. That line only makes sense while the file (or, with a trailing `/`, the folder) exists. If you delete the file, delete those lines too, or let `pmkit.py prune` do it.

## The helper script <!-- needs: .pmkit/ -->

It needs Python 3.8 or newer, with no extra packages and no network. Run it from the project root:

```bash
python .pmkit/pmkit.py prune --dry-run  # show lines that point to files you deleted
python .pmkit/pmkit.py prune            # remove them
python .pmkit/pmkit.py check            # missing core files, routes, adapters, links, placeholders, D-### pointers
python .pmkit/pmkit.py sync             # write the adapters enabled in .pmkit/adapters.txt
python .pmkit/pmkit.py log --type UPDATE --summary "Rewrote intro" --files docs/intro.md
python .pmkit/pmkit.py decide --title "Use SQLite" --why "One user, no server" --revisit "More than one writer"
```

On Windows, use `py` if `python` is not found. Add `--help` to any command for details.

What `check` and `prune` look at:

- Only the files pmkit created (the table above, knowledge/ and stages/). Your own README, CONTRIBUTING and docs are left alone.
- One exception: `check` scans every text file for pointers such as `see D-012`. A missing decision is an error, or only a warning if there is no DECISIONS.md. To skip files, list globs in `.pmkit/ignore.txt`, one per line (`legacy/` skips a folder).
- If DECISIONS.md is gone but `docs/adr/` exists, `prune` points the "Why is it like this?" row there.
- `check` is for agent setups with AGENTS.md. In a chat-window set it says so and stops.

Adapters: for Claude Code, enable the line `CLAUDE.md import` in `.pmkit/adapters.txt` and run `sync`. That writes a short CLAUDE.md that imports AGENTS.md. Many other agents read AGENTS.md directly and need nothing (checked 2026-10-17; please verify for your version). If someone edits a generated file by hand, `sync` will not overwrite it: it shows the diff and asks you to move the edit into AGENTS.md and run `sync --force`.

The script only checks and edits files. It cannot make an agent follow AGENTS.md; these conventions are requests to the model, not guarantees.

## Claude Code, `/init` and `#` memory

Claude Code reads CLAUDE.md, not AGENTS.md (checked 2026-10-17). The CLAUDE.md pmkit writes holds `@AGENTS.md`, so Claude Code reads AGENTS.md and, through it, RULES.md.

Claude Code also writes to CLAUDE.md itself (`/init`, and the `#` memory shortcut where it exists). That is fine: the `@AGENTS.md` line still works. Move useful additions, such as build and test commands, into AGENTS.md so every agent sees them.
`check` only warns about the additions. Once they are moved, `python .pmkit/pmkit.py sync --force` resets CLAUDE.md. <!-- needs: .pmkit/ -->

To keep your own CLAUDE.md instead, leave the adapter off and put `@AGENTS.md` in it.

## Rules of thumb

- Start small. Add a file, stage or tool only when something concrete calls for it, and write down why.
- Edit AGENTS.md, never the generated copies.
- Remove things that did not pay off, and write that down too.
