# Strix

> **Authorisation warning. Read this first.**
> Strix actively attacks its target. Use it **only on systems you own or have written permission to test.**
> **Never point it at production systems or at third-party targets** (other people's sites, APIs or repos).
> Unauthorised testing can be illegal. This kit does not vouch for the tool and gives no warranty.
>
> **Service-layer tool. Never installed at Level 2.** Level 3 only, as manual steps, always with `--max-budget` set.
> The project is classified **Alpha**.

## One-liner

An autonomous penetration-testing CLI: LLM agents probe a local directory, repo, URL or API spec inside a Docker sandbox and report findings with proof-of-concept evidence.

## Layer

**Service.** Docker, an LLM key (or a large local model), active network risk.

## What it does

- Targets (`--target` / `-t`, repeatable, or `--target-list`): a local directory, a GitHub repo URL, a live URL, an OpenAPI spec, or a Postman collection.
- Agents run tools and code inside a Docker sandbox image (pulled on first run) and try to confirm each finding with a PoC.
- `--instruction` passes free-text guidance, for example test credentials.
- Results go to `strix_runs/<run-name>`. `strix view` opens a local viewer on `127.0.0.1` with a tokened link.
- Scan modes: `quick` (minutes), `standard` (~30 min), `deep` (default, 1-4 hours).
- `--scope-mode auto` (default) limits PR runs to changed files in CI or headless runs. `diff` forces it, `full` turns it off.
- Headless (`-n`) exit codes: `2` = findings, `1` = fatal error. `--fail-on <severity>` sets the threshold. Interactive mode always exits 0.
- **`--max-budget <USD>` is a hard spend cap** across all agents. `--max-turns` caps steps. Without `--max-budget` there is no limit.

## What it does NOT do

- It does not review code quality or correctness. See [open-code-review.md](open-code-review.md).
- It does not replace a professional pentest where compliance requires one.
- It does not prove there are no vulnerabilities. A clean run is not a sign-off.
- It does not give a meaningful result for projects with no attack surface (research, writing, libraries or scripts with no exposed surface).
- Its README claims ("no false positives", "hours not weeks") have no benchmark or false-positive data behind them.

## Use when (triggers)

All of these:

- A web app or API is about to be exposed (staging or pre-release).
- **You own it, or have written permission to test it.**
- Docker is available.
- A spend cap is set (`--max-budget`).

## Skip when

- No attack surface. Keep a dependency and secret-scan checklist instead.
- No written authorisation. Never Strix.
- The target is production or belongs to someone else.
- No Docker.
- You would rely on a small local model for the security verdict.

## Install

Level 3, manual. Requires Docker running and Python 3.12+.

```bash
pipx install strix-agent
# upstream also offers: curl -sSL https://strix.ai/install | bash   (read the script before piping to bash)
```

Run against a **local, owned** target, with a cap:

```bash
strix --target ./app-directory --scan-mode quick --max-budget 5
```

CI on pull requests (owned repo only):

```bash
strix -n --target ./ --scan-mode quick --scope-mode auto --max-budget 10 --fail-on high
```

The CI workflow needs full git history (`fetch-depth: 0`) or `--diff-base`, or the diff-scope run exits 1.

Optional coding-agent skills: `npx skills add usestrix/strix` installs nine skills. Several steer toward the paid Strix Cloud. Skip unless you need them.

Version seen at check: v1.7.0 (2026-10-05). `pipx install strix-agent` installs the latest release; to pin one, use `pipx install strix-agent==<v>`. Record the version you install in `SETUP_DECISIONS.md` under "Installed tools".

## Files/settings it touches

- `strix_runs/<run-name>` in the current directory (findings, PoCs).
- `~/.strix/cli-config.json` (saved model and base-URL settings).
- `~/.strix/mcp-servers.json` if you add MCP servers for Strix to use.
- Docker: pulls and runs the sandbox image.
- A remote repo target is fetched into the sandbox.

## Network calls & data leaving the machine

- **Traffic to the target.** It actively probes it. This is the main risk; see the warning at the top.
- **With a cloud model**: your code, target responses and findings go to that LLM provider.
- **Credentials in `--instruction` are sent to the LLM.** Use test accounts only.
- The `strix view` link carries a token. Do not share it.
- **Strix Cloud** (`strix cloud`) is a separate paid service that uploads your source. Not used by this kit.
- Telemetry: not checked by the research.

## API keys

- Yes, unless you run a local model: `STRIX_LLM=provider/model` plus `LLM_API_KEY` (alias `OPENAI_API_KEY`).
- Or a ChatGPT subscription: `strix auth login chatgpt` with `STRIX_LLM=chatgpt/<model>`.
- This kit never asks for or stores keys.

## Local model route (exact env vars)

Via LiteLLM.

Ollama:

```bash
STRIX_LLM="ollama/<model>"
LLM_API_BASE="http://localhost:11434"     # aliases: OLLAMA_API_BASE, OPENAI_API_BASE, LITELLM_BASE_URL
# no key needed
```

LM Studio, vLLM or another OpenAI-compatible server:

```bash
STRIX_LLM="openai/<model>"
LLM_API_BASE="http://localhost:1234/v1"
```

Server settings for tool calls: Ollama `num_ctx` at least 16k-32k and thinking off; llama.cpp `--jinja`; vLLM `--enable-auto-tool-choice` with a matching `--tool-call-parser`. Temperature about 0.2-0.6.

**Small local models are unreliable here.** The upstream docs say most models under 70B "struggle", and models under ~30B emit malformed tool calls far more often. The local models they recommend are far beyond consumer hardware. Treat local mode as a privacy option only. **Do not treat a small-model run as a security sign-off.**

More in [guides/local-models.md](../guides/local-models.md).

## Privacy-safe settings

```bash
# Always cap spend:
#   --max-budget <USD>  [--max-turns <N>]
# Targets: local directories or owned staging only. Never production. Never third-party.
# Put only test credentials in --instruction.
# Do not use `strix cloud`.
STRIX_LLM="ollama/<model>"               # if code must not leave the machine (see local-model caveat)
LLM_API_BASE="http://localhost:11434"
```

## Conflicts/overlaps

- **Open Code Review**: different job (correctness vs exploitability). Running both on every PR doubles cost and minutes. Run OCR per PR and Strix nightly or before release.
- **Human review**: neither tool replaces human review of design and security decisions.

See [guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md).

## Cost & risk

- Setup: moderate (Docker, Python 3.12+, an LLM key).
- Cost: multi-step agent loops. No cost-per-scan data exists. Default `deep` mode runs 1-4 hours. Always set `--max-budget`.
- Legal and operational risk: it attacks things. Authorisation in writing, owned targets, never production.
- Agents execute code, contained by the Docker sandbox.
- Alpha status, plus commercial Cloud and Enterprise tiers alongside the open-source CLI. Pin the version (`pipx install strix-agent==<v>`) and record it.

## Upstream link

<https://github.com/usestrix/strix> (Apache-2.0 for the CLI; Cloud and Enterprise tiers are commercial)

## Checked: 2026-10-17

## Unverified

- Cost per scan and false-positive rates (no data exists).
- How the recommended local models perform. Hardware estimates for them come from general knowledge, not the repo.
- The content of the nine skills beyond their descriptions.
- Whether Strix sends telemetry, and how to turn it off.
