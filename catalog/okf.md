# OKF (Open Knowledge Format) v0.2

## One-liner

A small spec for a knowledge folder: markdown files with YAML frontmatter that both you and the LLM can read, write and check.

## Layer

**Method** (the spec). Nothing to install.

The optional reference agent is a **Service** (GCP, BigQuery billing, Gemini) and is out of scope for this kit.

Available at every level. This kit's `template/knowledge/` folder follows OKF v0.2.

## What it does

In this kit, OKF is the readable communication layer between you and the LLM. The agent writes what it learns into `knowledge/`. You read the same files, correct them, and mark what you have checked. Nothing is hidden in a database.

What the spec defines:

- A knowledge bundle is a folder of UTF-8 markdown files. Each "concept" file starts with YAML frontmatter. Its ID is its path without `.md`.
- `type` is the only key that is always required. Type values are free-form (for example `decision`, `glossary`, `dataset`, `system`).
- Recommended keys: `title`, `description`, `resource`, `tags`.
- Provenance: `sources` (where a fact came from).
- Trust: `generated: {by, at}` and `verified: [{by, at}]`. From these the spec derives three tiers: unverified, machine-confirmed, human-reviewed.
- Lifecycle: `status` (`draft`, `stable`, `deprecated`; default `stable`) and `stale_after` (a date after which the note should be re-checked).
- Reserved files: `index.md` (directory listing) and `log.md` (update history). The root `index.md` may carry `okf_version: "0.2"`.
- Concepts link to each other with plain markdown links.
- Readers must not reject a bundle for missing optional fields, unknown types or keys, or broken links.
- There is also an "Attested Computation" concept type, where the agent supplies only parameters and deterministic code checks the result.

How this kit uses it:

- `template/knowledge/index.md` is the bundle root (`okf_version: "0.2"`).
- `template/knowledge/log.md` is the reserved update history.
- `template/knowledge/example-concept.md` shows the frontmatter and explains the trust tiers.
- The agent sets `generated` when it writes a note. Only a person adds an entry to `verified`.
- `python .pmkit/pmkit.py check` checks that each concept file has frontmatter with a non-empty `type`, and warns when `stale_after` is in the past.

## What it does NOT do

- It is a format, not a tool. No search, retrieval, query engine or database.
- It has no official validator CLI. The `pmkit.py check` script is this kit's own minimal check, not part of OKF.
- Frontmatter does not make a note true. `verified` means only that someone recorded a check.
- It does not cover workflow routing. That is the job of `AGENTS.md` and stages (see [icm.md](icm.md)).

## Use when (triggers)

- Notes will be read by someone other than the author (team, reviewer, the person who takes over).
- The agent has acted on a stale or unverified note.
- The project produces lasting knowledge: decisions in depth, data descriptions, glossary, system notes.
- The agent keeps forgetting context between sessions (together with `STATUS.md`).

## Skip when

- The project is under about 2 weeks and solo. A README or one notes file is enough. Delete `knowledge/` (and run `python .pmkit/pmkit.py prune` if `.pmkit/` is present).
- You only need workflow structure, not stored knowledge.

## Install

Spec: nothing. Write markdown files with frontmatter. Read the spec in the maintained repo:

<https://github.com/GoogleCloudPlatform/open-knowledge-format>

Do not use the old copy under `GoogleCloudPlatform/knowledge-catalog/okf/`. Its own README says it is a frozen snapshot, no longer maintained, and points to the repo above.

Reference agent (optional, out of scope for this kit): Python 3.11 or newer, built on Google ADK, installed with `pip install -e .` from the repo, run as `reference-agent enrich --source bq ...` and `visualize`. It only reads BigQuery metadata plus web seed URLs, and only uses Gemini (default model `gemini-flash-latest`).

## Files/settings it touches

| Item | Writes |
|---|---|
| Spec | Only the files you or the agent write under `knowledge/` |
| `pmkit.py check` | Nothing. It reads `knowledge/*.md` and reports |
| Reference agent (out of scope) | `./bundles/<name>/` and `bundles/<name>/viz.html`; needs gcloud application-default credentials |

## Network calls & data leaving the machine

- Spec: none. Files go wherever your agent's model runs.
- Reference agent (out of scope): sends dataset metadata and fetched web pages to Google. BigQuery query bytes are billed to your project, even for public datasets. Its HTML viewer loads Cytoscape.js and marked from a CDN.

## API keys

- Spec: none.
- Reference agent (out of scope): `GEMINI_API_KEY`, or Vertex AI (`GOOGLE_GENAI_USE_VERTEXAI=true`, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_LOCATION`), plus gcloud credentials and a GCP billing project.

## Local model route (exact env vars)

- Spec: no env vars. Any model that can read and write files can use it, local or hosted.
- Reference agent: not supported. It has no LiteLLM, Ollama or OpenAI-compatible wiring. Using another model would mean changing its code.

See [guides/local-models.md](../guides/local-models.md).

## Privacy-safe settings

- Keep secrets, passwords and personal data out of `knowledge/`. The agent reads it and may send it to its model.
- If notes must stay on the machine, use a local model to read and write them.
- Do not run the reference agent.

## Conflicts/overlaps

- **Stage outputs vs concepts**: different units. Do not put OKF frontmatter on stage outputs.
- **graphify INFERRED edges and LangExtract records** are guesses. Never copy them into a concept's `verified` list without human review.
- **graphify** is a heavier way to navigate code and docs. It does not replace `knowledge/`. Markdown plus OKF frontmatter plus `log.md` stays the default for memory, because you can read, diff and fix it by hand.
- **Onboarding people**: when a person needs to learn the project, add glossary concepts here and add a short Onboarding section to `PROJECT.md` (the Level 3 interview adds it when you say a person must learn the project). A handoff diagram (Mermaid first, Archify if that is not clear enough) goes under "Add later" with the handoff date.

See [guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md).

## Cost & risk

- Spec: free, no dependencies, small token cost.
- The spec is early (v0.2). Breaking changes are allowed on major bumps. v0.1 fields have already changed: `timestamp` became `generated.at`, and the `# Citations` list became `sources`.
- The maintained repo had 6 commits on main and no releases when checked.
- The "not an official Google product" notice is in the knowledge-catalog README. It was not found in the new repo's README.

## Upstream link

<https://github.com/GoogleCloudPlatform/open-knowledge-format> (Apache-2.0)

Frozen older copy (do not use): <https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf>

## Checked: 2026-10-17

## Unverified

- The new repo's `connectors/` folder and other possible backends were listed, not explored.
- The maintained `SPEC.md` and the frozen copy were both v0.2 when checked. They may diverge later.
- The exact rules that map `generated` and `verified` to the three trust tiers are summarised here. Read the spec for the precise wording.
