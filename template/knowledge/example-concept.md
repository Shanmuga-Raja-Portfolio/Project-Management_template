---
type: example
title: Example concept
description: Shows every frontmatter field this kit uses. Delete this file once you have a real concept.
tags: [example, template]
sources:
  - resource: <fill in: a URL, file path, or "interview with <name>, <date>">
generated:
  by: <agent or model name>
  at: <YYYY-MM-DD>
verified: []
status: draft
stale_after: 2099-12-31
---

# Example concept

A concept is one unit of lasting knowledge: a term, a data source, a system, a decision explained in depth. Its ID is its file path without `.md`, so this one is `example-concept`.

## Fields

| Field | Required | Meaning |
|---|---|---|
| `type` | Yes | Free-form label, such as `glossary`, `dataset`, `system`, `decision`. The only required key in OKF v0.2. |
| `title`, `description`, `tags` | No (recommended) | What it is, in a line. |
| `sources` | No | Where the content came from. A list; each entry needs a `resource` (URL, file path, or a note such as "interview with Sam, 2026-10-17"). |
| `generated` | No | Who or what wrote it (`by`) and when (`at`). An agent sets this. If `generated` is present, `by` is required. |
| `verified` | No | List of `{by, at}` entries. A person adds one after checking the content. |
| `status` | No | `draft`, `stable` or `deprecated`. |
| `stale_after` | No | Date after which the content should be re-checked. pmkit reads it as `YYYY-MM-DD`. |

Conditionally required: `generated.by` when `generated` is present; `resource` on each `sources` entry; `runtime` for Attested Computation concepts. 
`pmkit.py check` flags the first two. <!-- needs: .pmkit/ -->

## Trust tiers

OKF derives a trust tier from `generated` and `verified`:

- **Unverified**: nothing in `verified`. Treat it as a claim, not a fact.
- **Machine-confirmed**: verified by an automated check.
- **Human-reviewed**: verified by a named person.

The exact rules for deriving tiers are in the upstream spec. Check SPEC.md there before relying on them (unverified in this kit).

Guesses from tools stay unverified. Inferred graph edges or LLM-extracted relations must not go into `verified` without a person reviewing them.

A person marks this file verified like this:

```yaml
verified:
  - by: <name>
    at: <YYYY-MM-DD>
```

## Body

Write the content below the frontmatter in plain markdown. Link related concepts with relative links, for example [index](index.md).
