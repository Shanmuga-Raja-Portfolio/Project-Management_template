---
okf_version: "0.2"
title: <fill in project name> knowledge
---

# Knowledge index

This folder is an OKF v0.2 bundle: markdown files with YAML frontmatter that people and agents can both read. Upstream spec: [GoogleCloudPlatform/open-knowledge-format](https://github.com/GoogleCloudPlatform/open-knowledge-format).

Put lasting knowledge here: decisions explained in depth, a glossary, descriptions of data and systems. Do not put stage outputs or daily notes here.

Rules:

- Every concept file needs frontmatter with a non-empty `type`. Everything else is optional.
- `index.md` and `log.md` are reserved names. `index.md` lists concepts. `log.md` records changes to this folder.
- Link concepts with plain relative markdown links.
- Only a person adds an entry to `verified`. An agent sets `generated` instead.
- `python .pmkit/pmkit.py check` checks for `type` and warns when `stale_after` has passed. <!-- needs: .pmkit/ -->

## Concepts

| Concept | Type | Status | Description |
|---|---|---|---|
| [example-concept](example-concept.md) | example | draft | Shows the frontmatter fields. Delete it once you have a real concept. <!-- needs: knowledge/example-concept.md --> |
