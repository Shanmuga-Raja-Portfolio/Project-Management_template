# Level 2: Starter + tools

The Level 1 interview plus a few questions, then a starter folder and an optional install of **light tools only**. Each installer asks before every step.

> Please read the [disclaimer](../../README.md#disclaimer) before installing any tool.

## Who it is for

- A solo person or single owner, as at Level 1, with a code project or a lot of existing text where one or two tools may pay off.
- You want to approve each install step and see what it touches.
- Service-layer tools (databases, Docker, keys, active risk) are out of scope. Strix is **never** installed at Level 2; if your answers point to one, the interview sends you to [Level 3](../3-interview/README.md).
- Chat window only? Level 2 adds nothing for you. See [guides/chat-window.md](../../guides/chat-window.md).

## What you get

- Everything from [Level 1](../1-starter/README.md): `SETUP_DECISIONS.md` and a starter folder cut to your answers.
- For each light tool: use now, skip, or add later on a named trigger. Often the answer is "none yet".
- A tool is recommended now only if its trigger holds now. Later needs (for example a handoff diagram in three months) go under "Add later" with a date or milestone.
- For each tool you accept: an installer you run yourself, a privacy-safe env example in `.pmkit/env/<tool>.env.example`, the exact version to record, and a revisit date. If you keep `LOG.md`, a `TOOL-ADD` entry too.

## The light tools

| Tool | Use it when | Key needed? | Card |
|---|---|---|---|
| Archify | Someone needs a diagram now that Mermaid cannot make clear. If only needed at a later handoff, add it then | No. Uses your agent's model | [catalog/archify.md](../../catalog/archify.md) |
| graphify (code-only) | The agent re-reads the same files every session, the codebase is large, or you inherited it | No, in code-only mode | [catalog/graphify.md](../../catalog/graphify.md) |
| Open Code Review (delegation) | The project is code in git, and you want reviews of changes or an audit of an inherited repo now | No, in delegation mode | [catalog/open-code-review.md](../../catalog/open-code-review.md) |
| LangExtract | You must turn a pile of text into records you can check against the source | Only for cloud models. None with local Ollama | [catalog/langextract.md](../../catalog/langextract.md) |

Fallback only: [workflow-graph](../../catalog/workflow-graph.md) renders DAGs in a web page that already exists. It does not run workflows, its npm build is stale, and it has no installer. Try Archify or Mermaid first.

## Short path (15-40 minutes)

1. Start the interview (see [How to run](#how-to-run)) and answer Q01 to Q11. Q08 (data sensitivity) is asked in full here, with options such as "local only" and "approved enterprise vendor only (Azure, Bedrock, Vertex)".
2. Approve `SETUP_DECISIONS.md` and the file list.
3. For each tool you accepted, do a dry run, then the real run, from your project root:

   ```bash
   bash /path/to/pmkit/levels/2-starter-tools/installers/<tool>.sh --dry-run
   bash /path/to/pmkit/levels/2-starter-tools/installers/<tool>.sh
   ```

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File C:\path\to\pmkit\levels\2-starter-tools\installers\<tool>.ps1 -DryRun
   powershell -NoProfile -ExecutionPolicy Bypass -File C:\path\to\pmkit\levels\2-starter-tools\installers\<tool>.ps1
   ```

   Add `--version <v>` / `-Version <v>` to pin an exact version. Without it you get the latest release, and the installer prints the version it installed. Archify cannot pin; there `--version` only checks what was installed ([details](installers/README.md#archify)).
4. Copy the printed version into the "Installed tools" table of `SETUP_DECISIONS.md`. If `LOG.md` exists, log a `TOOL-ADD` entry.

Every flag, step and file is explained in [installers/README.md](installers/README.md).

## Before you install

1. **The extra questions.** Level 2 asks the `L1` and `L2` questions in [interview/QUESTIONS.md](../../interview/QUESTIONS.md). The new ones: Q08 data sensitivity (in full), Q09 API budget and local hardware, Q10 volume of existing text, Q11 what went wrong before.
2. **The rules.** [interview/CONDUCT.md](../../interview/CONDUCT.md) (how the interview runs), [interview/MAPPING.md](../../interview/MAPPING.md) (answers to tools), [guides/overlaps-and-conflicts.md](../../guides/overlaps-and-conflicts.md) (tools that overlap).
3. **The card for each tool.** It lists what the tool does and does not do, the files it touches, its network calls, and what is unverified.
4. **Privacy.** If content must stay on your machine, read [guides/privacy-and-network.md](../../guides/privacy-and-network.md). Two traps:
   - The `/graphify` skill ignores `GRAPHIFY_BACKEND` and uses Gemini if `GEMINI_API_KEY` or `GOOGLE_API_KEY` is set. Code-only mode with the headless CLI avoids this.
   - Open Code Review, outside delegation mode and not configured, silently reuses your `ANTHROPIC_*` env vars.
5. **A local model**, if you plan to use one. `bash levels/2-starter-tools/installers/check-local-model.sh` only probes `localhost`. Base URLs and smoke tests are in [guides/local-models.md](../../guides/local-models.md).

## After you install

- **Record and log.** Put each exact version in `SETUP_DECISIONS.md`. If `LOG.md` exists:

  ```bash
  python .pmkit/pmkit.py log --type TOOL-ADD --summary "Added graphify 0.x (code-only): agent re-reads src/ every session" --files SETUP_DECISIONS.md
  ```

- **Revisit.** On the revisit date, keep the tool only if it paid off. To remove it, see [Removing a tool](installers/README.md#removing-a-tool), update `SETUP_DECISIONS.md`, and log a `TOOL-REMOVE` entry if `LOG.md` exists.
- **Working sessions** run as at Level 1: [Your first working session](../1-starter/README.md#your-first-working-session).

## How to run

**A. Claude Code skill.** Install it with `bash scripts/install-skill.sh` (Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install-skill.ps1`; Bypass applies to that one command only). Open your project in Claude Code, type `/project-setup`, and choose Level 2. The skill can suggest installers and runs one only after your explicit yes.

**B. Any LLM.** Paste [RUNFILE.md](RUNFILE.md) into a new chat, or attach it. It is roughly 15k tokens; on a local model, raise the context size first ([guides/local-models.md](../../guides/local-models.md)). The LLM tells you which installers to run, and you run them. `RUNFILE.md` is generated by `scripts/build_runfiles.py`; please do not edit it by hand.

**C. By hand.** Answer the `L1` and `L2` questions. Run `bash scripts/new-project.sh --minimal <target-dir>` (Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\new-project.ps1 -Minimal <target-dir>`), or `--only <files>` for your own list. Adjust to your answers, run `python .pmkit/pmkit.py prune`, read the cards, then run the installers you chose.

## Which model

Your choice. Routine work (renaming, formatting, simple extraction) can run on a local model through Ollama or LM Studio. Keep judgement-heavy work (design, review verdicts, decisions) on a stronger model if your Q08 answer allows it.

Tools that need tool calls, like Open Code Review in its own-LLM mode, are unreliable on small local models. The `/v1` suffix in the base URL differs per tool; [guides/local-models.md](../../guides/local-models.md) has the table.
