# Start here

A minute of reading, then you know which level to pick. If you are still unsure at the end, Level 1 is a good choice: you can add tools later.

## Only using a chat window in a browser?

If you use ChatGPT, Claude.ai or Gemini in a browser and the model cannot see your files, you need three small files:

- `PROJECT.md`: what the project is.
- `STATUS.md`: where it stands now.
- `RULES.md`: short working rules for the model.

[guides/chat-window.md](guides/chat-window.md) shows how to keep them and use them each session. For a short interview that drafts them, paste [levels/1-starter/RUNFILE.md](levels/1-starter/RUNFILE.md) into a new chat (on GitHub, use "Copy raw file") and say "browser chat window only" when asked which tool you use. You get those three files plus a short `SETUP_DECISIONS.md`, and nothing else.

That is all you need. The rest of this page is for people running an agent on a folder.

## Three questions to pick your level

Every level starts with an interview, so starting small does not mean missing anything.

**1. Do you want any of these?**

- A written plan before anything in your project changes. Nothing gets installed.
- A Service-layer tool such as Strix (security testing), with warnings and manual steps.
- A review of a tool that is not in the catalog ("bring your own tool").

Yes to any: **Level 3**. Otherwise, go on.

**2. Do you want any light tools installed now?**

The light tools are Archify (diagrams), graphify in code-only mode (a map of your code), Open Code Review in delegation mode (code review, for code in git) and LangExtract (pulling records out of text). Each installs locally, writes files, and runs no background service.

No, or not sure: **Level 1**. Yes, or maybe: go on.

**3. Are you happy to approve each install step yourself?**

The installers show every command, file and network call, and ask yes or no before each step.

Yes: **Level 2**. No: **Level 1** for now. [Adding tools later](guides/adding-tools-mid-project.md) is straightforward.

Whatever the level, the interview asks whether your project includes personal or confidential data, and whether it may be sent to a cloud AI service. Nothing goes to a cloud model unless you say it may.

## Your next step

| Level | With Claude Code | With any other agent or LLM | Read first (optional) |
|---|---|---|---|
| 1. Starter | Run `/project-setup`, choose Level 1 | Paste [the Level 1 RUNFILE](levels/1-starter/RUNFILE.md) (about 7k tokens) | [Level 1 README](levels/1-starter/README.md) |
| 2. Starter + tools | Run `/project-setup`, choose Level 2 | Paste [the Level 2 RUNFILE](levels/2-starter-tools/RUNFILE.md) | [Level 2 README](levels/2-starter-tools/README.md) |
| 3. Interview-led | Run `/project-setup`, choose Level 3. It first asks: plan only, or plan plus files? | Paste [the Level 3 RUNFILE](levels/3-interview/RUNFILE.md) | [Level 3 README](levels/3-interview/README.md), [overlaps and conflicts](guides/overlaps-and-conflicts.md) |

- **Claude Code:** clone the repo and install the skill from the repo root first ([how](README.md#option-b-claude-code-skill)), then open your project in Claude Code.
- **Level 2 installers** live in [levels/2-starter-tools/installers/](levels/2-starter-tools/installers/README.md). They run only when you start them and ask before every step. Try `--dry-run` (or `-DryRun` in PowerShell) first.
- **Local model?** Set the context window large enough for the RUNFILE first. See [guides/local-models.md](guides/local-models.md).

## Before you install anything

Please read the [disclaimer](README.md#disclaimer) before installing any tool.
