# Overlaps and conflicts

Several catalog tools do similar jobs. Running two on the same job costs more and gives you two answers that disagree. This page gives one decision rule per job and the conflicts to avoid.

The LLM uses it during the Level 2 and 3 interviews, when you [add a tool mid-project](adding-tools-mid-project.md), and when you [bring your own tool](bring-your-own-tool.md).

Facts here come from the kit's research, checked 2026-10-17. Tools change often, so read each [tool card](../catalog/README.md) before acting on a rule. Layers (Method, Tool, Service) are defined in the [catalog README](../catalog/README.md#layers); Service-layer items are Level 3 only.

## The general rule

- **Start with files and conventions** (the Method layer). Add a tool only when a [trigger](adding-tools-mid-project.md#triggers) holds now. Triggers that hold only at handoff or "later" go under "Add later" in `SETUP_DECISIONS.md` with a date or milestone.
- **One job, one tool.** If two fit, pick the lighter one.
- **Respect the upkeep cap** from the interview. It limits tools as well as files: at "minimal" upkeep, recommend no tool now unless its trigger is already hurting, and list the rest under "Add later".
- **Record every tool decision** with the trigger and a revisit date.

## Quick view

| Job | Default (no install) | Add on a trigger | Service option (Level 3 only) | Do not combine |
| --- | --- | --- | --- | --- |
| Project structure | One `AGENTS.md` + README | ICM stages | - | Several hand-edited root instruction files |
| Knowledge and memory | Markdown in `knowledge/` (OKF v0.2), plus `DECISIONS.md` and `LOG.md` if you keep them | graphify (code-only) for navigation | - | A second memory store beside `knowledge/` |
| Diagrams | Mermaid in markdown | Archify | - | Auto-syncing graphify into Archify |
| Workflow structure | ICM stages | Procedural-Graphs-style pitfalls | - | A big hand-written graph up front |
| Extraction from text | Read it yourself | LangExtract | graphify semantic pass with a cloud model | Two extractors on one corpus |
| Code review (code in git only) | Human or host-agent review | Open Code Review (delegation) | Strix (security only) | OCR and Strix on every PR |
| People learning facts | Glossary concepts in `knowledge/` + a short Onboarding section in `PROJECT.md` (added only when Level 3 says a person must learn the project) | Archify diagram, added near handoff | - | Onboarding notes kept outside the repo |

## O1. Project structure: ICM, icm-template, OKF, kit conventions

These are not four separate options. icm-template implements ICM. The kit's conventions (one canonical instruction file, an append-only log, the 90-10 rule) apply the same idea to every project. OKF covers only the `knowledge/` folder, not workflow routing.

### Decision rules

- **One-off small task:** none of these. A README and a short `AGENTS.md` are enough.
- **Existing repo, orientation without moving files:** icm-template quick mode (additive, no restructuring). First reuse what the repo already has (`docs/adr/`, `CONTRIBUTING.md`, an existing `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, CI review bots) instead of adding a parallel file.
- **New, repeatable, staged deliverable** (content pipeline, course, report series): ICM stages. See [template/stages/README.md](../template/stages/README.md).
- **Lasting knowledge others will rely on** (decisions, data descriptions, glossary): OKF v0.2 frontmatter on files under `knowledge/`. Every file stays readable, diffable and fixable by hand.

### Conflicts to avoid

- **Competing root instruction files:** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `IDENTITY.md`, `CONTEXT.md`, `.cursorrules` (legacy), `.cursor/rules/`, plus whatever graphify appends. The kit uses one canonical file, `AGENTS.md`.
  - Many agents read `AGENTS.md` directly and need no adapter (checked 2026-10-17; verify for your version).
  - Claude Code gets a short `CLAUDE.md` that imports `@AGENTS.md`.
  - Any other adapter is a generated copy with a "do not edit" header, made by `python .pmkit/pmkit.py sync`. sync refuses to overwrite an edited adapter (without `--force`) and shows the diff; `check` warns about it.
  - Claude Code's `/init` and `#` memory write to `CLAUDE.md`, so move what they add into `AGENTS.md`.
- **Two tools editing the same file:** `/icm-sync` and `graphify install` (which appends to `~/.claude/CLAUDE.md`) can both touch instruction files and cause churn. Keep graphify's block clearly marked, and re-run `python .pmkit/pmkit.py check` after.
- **Mixing units:** an ICM stage contract and an OKF concept are different things. Do not put OKF frontmatter on stage outputs.

## O2. Knowledge and memory: markdown vs graphify

Cheapest first. Move down only when the step above has clearly failed.

1. **Markdown in `knowledge/` with OKF v0.2 frontmatter.** The default, and the only memory the kit uses. `DECISIONS.md` records what was decided and why. `LOG.md` records what happened; for code in git it is optional, because `git log` already covers actions. For long-running projects, keep `knowledge/index.md` current and let the agent grep before it asks.
2. **graphify**, when the problem is structural navigation of a medium or large codebase or mixed corpus ("what connects X to Y", "which modules are central"). Output is files; no service runs. Use code-only mode (`GRAPHIFY_BACKEND=none`) if docs must not leave the machine. graphify helps the agent find things; it is not a second place to store facts.

### Conflicts to avoid

- No second memory store (a memory service, a capture plugin, a vector database) beside `knowledge/`. Two stores give two competing "truths", double ingestion cost, and drift you reconcile by hand.
- graphify's community labelling can fall back to `claude -p` on your subscription. Turn this off explicitly: `GRAPHIFY_BACKEND=none`.
- graphify INFERRED edges are guesses. Never mark them OKF `verified` without a human check.

## O3. Diagrams: Mermaid vs Archify vs graphify vs workflow-graph

- **Mermaid in markdown** (default): zero install, diffable.
- **Archify:** a curated, validated diagram people will read now (a review or meeting this week). If it is only needed at handoff or onboarding, put it under "Add later" with that milestone.
- **graphify** (`graph.html`): to discover the structure that exists, not draw the one you intended.
- **workflow-graph** (fallback, Level 3): only if the product already has a web front end that must show live DAG status. It renders graphs; it does not run workflows. The npm build (0.1.2, Jan 2024) is stale.

**Conflict:** the discovered graph (graphify) and the intended graph (Archify) will disagree. That is useful review input. Do not auto-sync one into the other.

## O4. Workflow structure: ICM stages vs Procedural Graphs vs workflow-graph

These work together. ICM stages are the container. The Procedural Graphs paper adds a method for each handoff: give it a condition, guidance and pitfalls, and show the agent only the current stage and its next steps. workflow-graph only draws.

- Add pitfalls to a stage contract (`stages/NN-*/CONTEXT.md`) once that stage has failed the same way twice.
- Do not try self-evolving procedures without a validation set and a score.

**Conflict:** writing a big "expert" graph up front. The paper reports that a hand-written expert graph lowered success until its evolution step repaired it. Grow pitfalls from observed failures.

## O5. Extraction from text: LangExtract vs graphify semantic pass

- **Auditable records with source spans** (requirements, decisions, entities from interviews or contracts): LangExtract.
- **Relationships for navigation:** graphify semantic pass.
- **Facts for later recall:** write the checked results into `knowledge/` notes and record the choice in `DECISIONS.md`.

**Conflict:** running both over one corpus pays for two LLM passes and gives two unreconciled versions. Pick one per corpus and record it.

## O6. Review: Open Code Review vs Strix

Different jobs. Open Code Review (OCR) checks the quality and correctness of diffs. Strix tests whether a running app can be exploited. Neither replaces a human review of design decisions, and both apply only to code in git.

- **Diffs being reviewed now**, past the prototype stage: OCR in delegation mode. Your host agent does the review, so there is no extra key.
- **`ocr scan` of an inherited repo: always "Add later"**, never at setup, with a date or milestone (for example "after the first month of changes" or "before the handoff review"). A scan reads whole files, so on a large repo it uses many tokens on your agent's model. When you run it, scope it to the folders you are changing (`ocr scan --path <dir>`). Reviewing your own diffs on an inherited repo is the delegation rule above, not a scan.
- **A CI review bot already exists:** reuse it. Do not add OCR beside it.
- **A web app or API you own, or have written permission to test, about to be exposed:** add Strix before release, or in CI with `--scan-mode quick --scope-mode auto --max-budget N --fail-on high`. Level 3 only, manual steps.

### Conflicts

- OCR silently reuses `ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_MODEL` if it has no config. Set `~/.opencodereview/config.json` explicitly, or use delegation mode.
- Running both on every PR doubles LLM cost and minutes. Run OCR per PR and Strix nightly or before release.
- Never point Strix at production or at third-party systems.

## O7. People learning project facts

No tool needed. When new people must learn the project, give them:

- Glossary concepts in `knowledge/` (OKF `type: glossary`), so each term has one definition.
- A short Onboarding section in `PROJECT.md`: where to start reading, who decides what, and how to run the project. The template does not include it; the Level 3 interview adds it when you say a person must learn the project.
- An Archify diagram, added near the handoff, only when Mermaid cannot make the structure clear.

Skip all of this for a short, solo project.

## Checklist for the LLM

Before recommending or adding a tool:

1. Which job above does it do?
2. Does its trigger hold now? If only at a later milestone, put it under "Add later" with the date.
3. Is something already chosen for that job in `SETUP_DECISIONS.md`, or already in the repo (CI bot, ADR folder)? If yes, say so and recommend one, not both.
4. Does it write to a file another tool also writes (`CLAUDE.md`, git hooks, `~/.claude/settings.json`)?
5. Does it send data off the machine by default? See [privacy-and-network.md](privacy-and-network.md).
6. Is it in the Service layer? If yes, it is Level 3 only, with a warning.
