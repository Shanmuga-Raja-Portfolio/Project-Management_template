# workflow-graph (fallback)

## One-liner

A web component from Google that draws a DAG with a status badge per node. It renders only. It does not run workflows.

## Layer

**Tool** (npm package, no service). **Fallback** to [Archify](archify.md).

Level 3 only. Not offered by the Level 2 installers.

The author of this kit used it only as a fallback when Archify did not fit. This card is short on purpose.

## What it does

- Renders directed acyclic graphs or trees in a web page, with toolbar, sticky scaffold and status icons per node state.
- You supply nodes and edges (`DagNode`, `DagEdge`, `GraphSpec`).
- `npm run build-web-component` builds a framework-agnostic bundle (`dist/registerWorkflowGraphWebComponent.js`).

## What it does NOT do

- Does not run, plan or orchestrate workflows. No LLM. No CLI, MCP server or Python library.
- It is not LangGraph and not Google ADK workflows.
- The Angular-library path is marked "Coming soon". The package is labelled `[WIP]`.

## Use when (triggers)

- The product itself already has a web UI that must show live pipeline or DAG status.

## Skip when

- Every other case. A Mermaid block, an [Archify](archify.md) diagram or a status table in `STATUS.md` is lighter.
- No web front end.

## Install

```bash
npm install @google/workflow-graph
# yarn: yarn add @google/workflow-graph   (the README's "yarn install <pkg>" is wrong)
```

npm `latest` is **0.1.2 from January 2024**. The repo shows 0.1.3, which was never published. Almost 3 years of source changes are only available by building from source (`pnpm install`, `npm run build-web-component`). Whether that build works as-is is unverified. Record the version you install in `SETUP_DECISIONS.md` under "Installed tools".

## Files/settings it touches

| Command | Writes |
|---|---|
| `npm install` | `node_modules/`, `package.json`, lock file in your web project |
| Build from source | `dist/`, `dist-types/` in the clone |

## Network calls & data leaving the machine

- Install: npm registry download.
- Runtime: none documented. It is a client-side renderer.

## API keys

None.

## Local model route (exact env vars)

Not applicable. No model.

## Privacy-safe settings

Nothing to set.

## Conflicts/overlaps

- **Archify**: the main choice for shareable diagrams. Use workflow-graph only for live status in an existing web UI.
- **Procedural Graphs pattern / ICM stages**: they structure the work; workflow-graph only draws a picture of it.

See [guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md).

## Cost & risk

- Pulls in an Angular 17 bundle with Angular Material and zone.js. Heavy for a diagram.
- The public repo is a one-way export of an internal Google component. Not community-driven.
- README: "not an officially supported Google product".

## Upstream link

<https://github.com/google/workflow-graph> (Apache-2.0)

## Checked: 2026-10-17

## Unverified

- Whether a build from source works with the declared Angular 17 config.
- Compatibility with React 19 or other frameworks. The only linked example is a third-party React 18 project.
