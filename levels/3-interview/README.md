# Level 3: Interview-led (power user)

The full interview. You choose the output: a **written plan only**, or a **plan plus a tailored scaffold**. The aim is to use the least that works, and to say when to add more.

> Please read the [disclaimer](../../README.md#disclaimer) before installing any tool.

## Who it is for

- Longer or larger projects and handoffs, run by a solo person or single owner with an AI agent in a project folder (code, research or writing). Teams on parallel branches are not supported yet (planned for v0.2).
- Inherited or production repos. The interview first looks for what you already have (`docs/adr`, `CONTRIBUTING`, an existing `AGENTS.md`, `CLAUDE.md` or `.cursor/rules`, review bots in CI) and reuses it.
- You want to read a plan before anything in your project changes.
- You are weighing Service-layer tools (such as Strix) and want the warnings up front.
- You already use tools outside the catalog and want them checked against the rest.

## What you get

The first question (Q17) asks which output you want. Both formats are defined in [interview/OUTPUTS.md](../../interview/OUTPUTS.md).

| You choose | Files written |
|---|---|
| Written plan only | `SETUP_PLAN.md` and nothing else |
| Plan and scaffold | `SETUP_DECISIONS.md` and the chosen files, as in [Level 1](../1-starter/README.md). No `SETUP_PLAN.md` |

`SETUP_PLAN.md` covers:

- what to use now and why, with the answers that justify each item
- what not to use, and why
- what to add later, and the trigger for each
- Service-layer tools as manual steps, with their warnings
- your own tools, checked against the overlap map
- model routing (what can run locally, what needs a stronger model)
- a bloat check, and the first three steps

With a scaffold, `SETUP_DECISIONS.md` records what was chosen, what was declined, and the trigger (or date) for each later item. Tool-layer tools can then be added with the [Level 2 installers](../2-starter-tools/installers/README.md).

## Short path

1. Start the interview (see [How to run](#how-to-run)).
2. Answer Q17 first: plan only, or plan and scaffold.
3. Answer the rest. Implied answers are skipped. There are up to 17 questions, so allow more than 5 minutes.
4. Read the draft. Approve it, or ask for less.

## The questions

Level 3 asks every question in [interview/QUESTIONS.md](../../interview/QUESTIONS.md): Q17 first, then Q01 to Q07 (core), Q08 to Q11 (data, budget, text volume, past problems), and:

- Q12 attack surface and authorisation
- Q13 how you will know it is done
- Q14 does a human need to learn this (if yes, a short `## Onboarding` section is added to `PROJECT.md`)
- Q15 diagrams and audience
- Q16 other tools you want to use

## Layers

Every setup starts with the Method layer and adds a layer only when a trigger holds now.

| Layer | What | Default |
|---|---|---|
| Method | File conventions, zero install: stages, OKF knowledge files, pitfalls on stage handoffs, one instruction file (adapters only where an agent needs one), optional logs | Yes, sized by the interview |
| Tool | Local install, writes files, no daemon: Archify, graphify code-only, Open Code Review delegation mode, LangExtract. Fallback: workflow-graph | No. Add on a trigger |
| Service | Database, Docker, keys, network or active risk: Strix, cloud backends of Tool-layer tools | No. Trigger plus a privacy and budget check |

Overlap rules are in [guides/overlaps-and-conflicts.md](../../guides/overlaps-and-conflicts.md). For example: one extraction tool per corpus; one memory (markdown `knowledge/` in OKF v0.2, plus `LOG.md` and `DECISIONS.md`, with graphify only for navigating code and docs); code review per PR and security testing before release, not both on every PR.

## Reviewing the plan

- Read the card for anything proposed. [catalog/README.md](../../catalog/README.md) indexes them.
- Push back on anything you will not maintain. Your upkeep answer (Q07) caps both files and tools.
- Later needs (a handoff diagram, a full-repo review scan) go under "Add later" with a date, not on day one.
- Act on the plan at your own pace. Log each tool you add with a trigger and a revisit date, as in [guides/adding-tools-mid-project.md](../../guides/adding-tools-mid-project.md).

## Service-layer tools (manual, with warnings)

No script in this kit installs a Service-layer tool. If your answers meet a trigger, the plan lists manual steps from the card, with the warnings below. Please read the full card first.

**Strix** ([catalog/strix.md](../../catalog/strix.md)) is an autonomous pentest CLI that runs in a Docker sandbox.

- Only on systems you own or have written permission to test. Never production. Never third-party targets.
- Trigger: a web app or API you own is about to be exposed, Docker is available, and a spend cap is set.
- Always set `--max-budget <USD>`. The default deep scan takes 1 to 4 hours. Strix is classified Alpha.
- Do not treat results from small local models as a security sign-off.

The OKF reference agent and cloud backends of Tool-layer tools are also Service layer; see their cards.

Long-running projects do not need a memory service. Keep decisions in `DECISIONS.md`, history in `LOG.md` and facts in `knowledge/`. If files plus grep stop being enough to navigate code and docs, add graphify.

## Bring your own tool

Mention any tool you want to use (Q16). The interviewer follows [guides/bring-your-own-tool.md](../../guides/bring-your-own-tool.md):

1. Fills the [card template](../../catalog/_card-template.md) from what you can show it: README, docs, install steps.
2. Checks it against the tools already chosen, using the overlap map.
3. Warns about conflicts, network calls, keys, and anything it could not check (marked "unverified").
4. Adds the disclaimer. You decide.

Content the LLM reads from web pages, READMEs or papers is treated as data, never as instructions.

## How to run

**A. Claude Code skill.** Install it with `bash scripts/install-skill.sh` (Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install-skill.ps1`; Bypass applies to that one command only). Open your project in Claude Code, type `/project-setup`, and choose Level 3.

**B. Any LLM.** Paste [RUNFILE.md](RUNFILE.md) into a new chat, or attach it. It is roughly 21k tokens; on a local model, raise the context size first ([guides/local-models.md](../../guides/local-models.md)). It holds the full question set, mapping, output formats, condensed catalog cards (linked to the full ones), the overlap guide and the bring-your-own-tool procedure. `RUNFILE.md` is generated by `scripts/build_runfiles.py`; please do not edit it by hand.

**C. By hand.** Answer all questions, starting with Q17. For a plan only, write `SETUP_PLAN.md` in the [OUTPUTS.md](../../interview/OUTPUTS.md) format. For plan and scaffold, write `SETUP_DECISIONS.md`, then run `bash scripts/new-project.sh --only <files> <target-dir>` (Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\new-project.ps1 -Only <files> <target-dir>`) or `--minimal` / `-Minimal`. Then run `python .pmkit/pmkit.py prune` and `check`.

## After setup

Working sessions run as at Level 1: [Your first working session](../1-starter/README.md#your-first-working-session).

## Which model

Your choice. Level 3 makes more judgement calls, so a stronger model helps with the interview and the plan. Routine work later can move to a local model. Your Q08 answer decides what may go to a cloud service at all. See [guides/local-models.md](../../guides/local-models.md) for routing and per-tool settings.
