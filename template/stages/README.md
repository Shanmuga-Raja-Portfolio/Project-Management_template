# Stages (optional)

Use stages only for a repeatable process: the same multi-step deliverable made more than once (a report series, a course, a content pipeline). For a one-off project, delete this whole folder.

The idea comes from ICM (Interpretable Context Methodology): numbered folders, each with a `CONTEXT.md` contract. The agent reads only the contract for the stage it is working on, not the whole project.

## Layout

```
stages/
  01-<name>/
    CONTEXT.md     contract: Inputs, Process, Outputs, Pitfalls
    references/    material this stage needs (create when needed)
    output/        what this stage produces; the next stage reads it (create when needed)
  02-<name>/
    ...
```

## How to use

1. Copy `01-example/` for each stage. Rename it `NN-short-name`.
2. Fill in Inputs, Process and Outputs. Keep each contract short.
3. Leave Pitfalls empty at first. Add one only after a stage has failed the same way twice.
4. Do not put OKF frontmatter on stage outputs. Lasting knowledge goes in `knowledge/`.
5. Add a row to the routing table in AGENTS.md if the agent needs help finding the right stage. <!-- needs: AGENTS.md -->

## Why pitfalls start empty

The pitfalls section borrows from the Procedural Graphs paper (arXiv 2609.09153): each handoff between stages carries a condition, guidance and pitfalls. The paper found that a large hand-written "expert" procedure written up front lowered success until it was repaired from observed failures. So grow pitfalls from what actually went wrong. Do not write a big one up front.
