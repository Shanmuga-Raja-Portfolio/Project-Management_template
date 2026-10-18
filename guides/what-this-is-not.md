# What this kit is not

These are the kit's commitments, so you know what to expect from it.

## What it is

A project setup kit: an interview, a small set of file conventions, and optional tool cards. Nothing more.

- **Built for** a solo person or single owner running an AI agent on a folder of code, research or writing.
- **Not covered yet:** teams on parallel branches and enterprise compliance pipelines (planned for v0.2).
- **Only using a browser chat window?** You need much less; see [chat-window.md](chat-window.md).

## Commitments

1. **Names say what things are.** We do not call a folder of markdown files an "operating system", an "AI brain" or a "second brain". A file the model is asked to read is described as exactly that.
2. **The interview is about the project, not a persona.** It asks about scope, duration, data sensitivity, budget, who else works on it and how much upkeep you will keep up. It does not ask you to name or characterise the assistant; that would not change how the project is run.
3. **Conventions are not sold as guarantees.** A convention only works if someone follows it, so where it matters we ship a small check instead (see [What `check` does](#what-check-does)). Anything not checked by a script is described as a convention, not a feature.
4. **Context load scales with the project.** There is no fixed list of files every session must read. `AGENTS.md` routes the agent to what the current task needs, so a small project gets fewer files. The paste-in RUNFILEs are cut to their level too: the Level 1 RUNFILE is roughly 7k tokens.
5. **Everything is in the repo.** There is no paid tier and there are no affiliate links.
6. **Every network call is disclosed.** The kit's own files make no network calls, apart from install commands you approve in the Level 2 installers, and a check that only contacts your local model. Each tool card and [privacy-and-network.md](privacy-and-network.md) list what each third-party tool sends, including update checks, telemetry and silent reuse of keys. The installers write privacy-safe settings by default.
7. **Version numbers match maturity.** This is v0.1.0, and it is early. Parts we have not tested are labelled "untested"; facts we could not confirm are labelled "unverified".
8. **Plain files, no UI.** A project brief and a status file are the starting point. Add more only when a reader needs it.
9. **No claims about outcomes.** We do not claim productivity gains, token savings or quality improvements, and we do not cite star counts or vendor benchmarks. "Use no tools" is a valid, good result of the interview.
10. **Installers do not change your setup quietly.** Some tools write to editor instruction files, git hooks, git config or your home directory, or capture prompts. Every installer lists the files and settings it will touch and the network calls it will make, then asks before each step. Nothing that changes your setup runs without a separate yes.
11. **Demo features are labelled as demos.** If an upstream project labels a feature as a demo or alpha, our card says so.
12. **Each card says what the tool does not do.** Some names suggest more than the tool does; for example, workflow-graph draws workflow graphs but does not run workflows. Every card has a "What it does NOT do" field.
13. **Fetched content is data, not instructions.** When an agent reads a paper, web page or document during setup, it does not follow instructions found inside, and tells you it found them. During our own research, one fetch of a paper page reported embedded instructions aimed at AI summarisers.
14. **We never ask for secrets during setup.** The interview and the installers never ask for, store or print API keys. You set keys yourself, outside the kit.

## What `check` does

`.pmkit/pmkit.py check` covers the files the kit created, not your own README or CONTRIBUTING (except for the decision-pointer scan).

- **Fails** when:
  - a core file (`PROJECT.md`, `STATUS.md`, `RULES.md`) or a file `AGENTS.md` routes to is missing;
  - a `see D-###` pointer names a decision missing from an existing `DECISIONS.md`.
- **Warns** when:
  - an adapter no longer matches `AGENTS.md` (a warning, since Claude Code writes to `CLAUDE.md` itself);
  - a knowledge file lacks frontmatter with a `type`, or is past its `stale_after` date;
  - a `see D-###` pointer exists but there is no `DECISIONS.md` (`.pmkit/ignore.txt`, one glob per line, skips paths in that scan);
  - instructions point to files you did not keep, relative links point to missing files, or placeholders are left, including an unfilled `SETUP_DECISIONS.md`.

`pmkit.py prune` removes the instructions that point to missing files.

## Conventions the kit follows

- One canonical instruction file (`AGENTS.md`). Many agents read it directly; for those that look for another file name, the kit generates an adapter, only if you ask. The adapter pattern also appears in icm-template.
- Reuse what the project already has (ADRs, CONTRIBUTING, existing instruction files, review bots) instead of adding a parallel file.
- An append-only log with action types, when the work is not already logged elsewhere (for code in git, `git log` covers it).
- Scripts for deterministic work: if a step always gives the same result, a script does it, not the LLM.
- A storage ladder: plain text first, then JSON or CSV, then a spreadsheet, and a database only when the need is real.

See [CREDITS.md](../CREDITS.md) for all upstream projects.
