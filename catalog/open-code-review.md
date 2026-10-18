# Open Code Review (OCR)

## One-liner

A Go CLI (`ocr`) that reviews git diffs or whole files and returns line-level comments. In delegation mode your own agent does the review, with no extra key.

## Layer

**Tool** in delegation mode (recommended in this kit). It becomes a **Service** when OCR calls its own cloud LLM provider.

Available at Level 2 (installer, delegation mode) and Level 3 (own LLM / CI).

## What it does

- Reviews git diffs: workspace changes, a branch range (`--from` / `--to`, via merge-base) or one commit (`--commit`).
- `ocr scan --path <dir>` reviews whole files, which is useful for auditing an inherited repo.
- File selection, bundling, rule matching and comment positioning are deterministic code. An agent only fetches context and makes judgement calls.
- **Delegation mode** (`ocr delegate preview`, `ocr delegate rule`) makes no LLM call on the OCR side. OCR outputs the files to review and the matching rules; the host agent (for example Claude Code) reviews with its own model.
- JSON output (`--format json --output result.json`), resumable sessions, and a browser session viewer where comments can be marked fixed or ignored.
- CI examples: GitHub Actions, GitLab CI, Gerrit, GitFlic, Bitbucket Pipelines, Codeup.

## What it does NOT do

- It does not test exploitability. That is a security tool's job (see [strix.md](strix.md)).
- It does not replace human review of design decisions.
- It does not aim for maximum recall. The authors say they trade recall for precision.
- It does nothing for projects with no git or no code. This kit never recommends it unless the project is code in git.

## Use when (triggers)

Required for every trigger: the project is code, and it is in git (interview Q01 = code, with git). Being a team or having a handoff is not enough on its own.

Then, only when the trigger holds now:

- Delegation mode: first PRs or merges on shared code are happening, or you are reviewing your own diffs on an inherited repo.
- Own LLM / CI mode (Level 3 only): a team PR flow exists where reviews must be repeatable and not depend on one person's agent.

Add later (not at setup): any `ocr scan` of an inherited or whole repo, including one before a handoff. Put it under "Add later" in `SETUP_DECISIONS.md` with the date or milestone. A scan reads whole files, so on a large repo it uses many tokens; scope it with `--path` to the folders you are changing.

## Skip when

- No git, or no code (research, writing, documents). This rule has no exception.
- Solo prototype where a review pipeline is too much process (for the CI mode).

## Install

Prerequisite: Git 2.41 or later.

```bash
npm i -g @alibaba-group/open-code-review     # provides the `ocr` command
# or: brew install open-code-review
# or: a release binary, checked against sha256sum.txt
```

Delegation mode in Claude Code. Run these **inside Claude Code**:

```text
/plugin marketplace add alibaba/open-code-review
/plugin install open-code-review@open-code-review
```

This adds `/open-code-review:review` and `/open-code-review:delegate-review`. Use `delegate-review` for delegation mode. Which provider `:review` uses is not documented in the research (it likely uses OCR's own provider; unverified).

Delegation for other agents: `npx skills add alibaba/open-code-review --skill open-code-review-delegate`.

The upstream also offers `curl ... | sh` and `irm ... | iex` install scripts. This kit's installer uses npm instead.

The Level 2 installer is in [`levels/2-starter-tools/installers/`](../levels/2-starter-tools/installers/README.md) (`open-code-review.sh` / `open-code-review.ps1`). It prints the plugin commands for you to run. It does not configure a provider.

Version seen at check: v1.13.1 (2026-10-17). The installer installs the latest release by default and prints the exact version. To pin one, pass `--version <v>` (`-Version <v>` in PowerShell), or by hand: `npm i -g @alibaba-group/open-code-review@<v>`. Record the version you install in `SETUP_DECISIONS.md` under "Installed tools".

## Files/settings it touches

- Global npm install of the `ocr` binary.
- `~/.opencodereview/config.json` (provider, model, telemetry settings) when you run `ocr config ...`.
- The Claude Code plugin is installed by Claude Code's plugin system. Delegation can also be installed as a command file at `.claude/commands/delegate-review.md`.
- `--output <file>` writes review results where you point it.

## Network calls & data leaving the machine

- **Delegation mode**: OCR makes no LLM call. Your code goes wherever your host agent's model already sends it, and nowhere else.
- **Default mode**: diffs and file contents go to the configured LLM provider. Many of the 28 built-in presets are hosted in China (DashScope, Qianfan, Volcengine and others). Choose a provider on purpose.
- **Silent fallback**: if nothing is configured, OCR looks up credentials in this order: `~/.opencodereview/config.json`, then `OCR_LLM_URL` / `OCR_LLM_TOKEN` / `OCR_LLM_MODEL`, then **`ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_MODEL`**, then the shell rc file. So with Claude Code's Anthropic env vars set, a non-delegated `ocr review` can bill and route through them without asking.
- **Telemetry is off by default.** It is opt-in (`OCR_ENABLE_TELEMETRY=1`). The default exporter is the console. OTLP export goes only to an endpoint you set; there is no built-in vendor endpoint. Prompt/response content logging is a separate opt-in (`OCR_CONTENT_LOGGING=1`).

## API keys

- Delegation mode: none on the OCR side.
- Default mode: one provider key (28 preset env vars, for example `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`). Bedrock uses AWS credentials.
- Custom providers need a non-empty `api_key` in config and have no env-var fallback. For a local server, any placeholder works.
- This kit never asks for or stores keys.

## Local model route (exact env vars)

Simplest local route: **delegation mode** with a host agent that already runs a local model.

OCR's own LLM on Ollama, as a custom provider (from the upstream configuration doc):

```bash
ocr config set provider ollama
# then set these keys (check the exact `config set` syntax in the upstream configuration.md):
#   custom_providers.ollama.url      = http://127.0.0.1:11434/v1
#   custom_providers.ollama.protocol = openai
#   custom_providers.ollama.model    = qwen3:32b
#   custom_providers.ollama.api_key  = ollama   (placeholder; must be non-empty)
```

Or by env vars:

```bash
OCR_LLM_URL=http://127.0.0.1:11434/v1
OCR_LLM_TOKEN=ollama
OCR_LLM_MODEL=qwen3:32b
OCR_LLM_PROTOCOL=openai
OCR_LLM_TIMEOUT=900        # default is 300 s; raise it for slow local models
```

The model **must support native tool calls**. qwen3 works; deepseek-r1 fails with "No tool calls parsed". LM Studio (`http://localhost:1234/v1`) uses the same pattern but is undocumented upstream.

More in [guides/local-models.md](../guides/local-models.md).

## Privacy-safe settings

- Use delegation mode (`/open-code-review:delegate-review`).
- If you ever run `ocr review` with OCR's own LLM, set `~/.opencodereview/config.json` explicitly first, so it does not fall back to `ANTHROPIC_*`.
- Leave telemetry and content logging unset (both are off by default):

```bash
# OCR_ENABLE_TELEMETRY   leave unset
# OCR_CONTENT_LOGGING    leave unset
```

## Conflicts/overlaps

- **Strix**: not the same job. OCR checks correctness and quality of diffs; Strix checks exploitability of a running target. Running both on every PR doubles LLM cost and minutes. Run OCR per PR and Strix nightly or before release.
- **Claude Code env vars**: the `ANTHROPIC_*` fallback above.
- **Human review**: OCR comments are input to a human decision, not a sign-off.

See [guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md).

## Cost & risk

- Setup: one npm global install or one binary. Light.
- Delegation mode adds no key and no extra LLM bill; the review uses your host agent's tokens.
- Default mode: provider spend, plus data routing to the chosen provider.
- Young project (created 2026-05), very fast release pace. The installer takes the latest release unless you pass `--version`; record the version it prints in `SETUP_DECISIONS.md`.
- The benchmark in the README (AACR-Bench) is built by an Alibaba team and its comparison numbers appear only in an image. This kit does not cite it.

## Upstream link

<https://github.com/alibaba/open-code-review> (Apache-2.0). The docs on open-codereview.ai returned 404 at check time; the same docs are in the repo under `pages/src/content/docs/en/`.

## Checked: 2026-10-17

## Unverified

- The exact `ocr config set` key syntax for custom providers.
- LM Studio as a provider (undocumented upstream).
- ACP support (an `acp/` directory exists; not described).
- Which LLM `/open-code-review:review` uses (inferred to be OCR's own provider).
- The README's token and precision claims (vendor benchmark, not reproduced).
