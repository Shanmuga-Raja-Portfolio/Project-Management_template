# Local models

You choose the model; any capable LLM can run the interview. This guide covers running part of the work on a local model (Ollama or LM Studio) and keeping the rest on a frontier model.

Facts here come from the kit's research, checked 2026-10-17. Env vars and defaults in these tools change often, so check the tool card and upstream docs before relying on them.

## Why run a local model

- **Cost.** Routine, mechanical work does not need a paid frontier model.
- **Privacy.** Content sent to a local server stays on your machine.

Treat local mode as the privacy option, not a free copy of a frontier model.

## What to route where

| Task | Local model | Frontier model |
| --- | --- | --- |
| Summarising logs or long output | OK | - |
| Drafting `LOG.md` and `STATUS.md` updates | OK | - |
| Extraction passes (LangExtract) on simple records | OK, expect lower recall | Better for hard or messy text |
| Labelling, tagging, sorting | OK | - |
| Reformatting, renaming, converting files | OK | - |
| First-draft knowledge notes (mark them unverified) | OK | - |
| Architecture and design decisions | - | Recommended |
| Security review sign-off | - | Recommended. Do not trust a small model's security result as a sign-off |
| Agentic tool-calling loops (OCR own-LLM mode, Strix, coding agents) | Unreliable below ~30B parameters | Recommended |
| Final review before handoff or release | - | Recommended |
| Running the setup interview | Possible with a capable model and enough context (see below) | Recommended for Level 3 |

A simple rule: if a mistake is cheap to spot and fix, a local model is fine. If it is costly or hard to spot, use a frontier model and a human check.

## Context length: set it before you paste a RUNFILE

A local server reads only as many tokens as its context window allows. Anything longer is dropped, usually without an error, and the model still answers, but badly.

| RUNFILE | Size budget | Context to set (RUNFILE plus room for the conversation) |
| --- | --- | --- |
| Level 1 | roughly 7k tokens | at least 16k (`num_ctx 16384`) |
| Level 2 | roughly 15k tokens | at least 32k (`num_ctx 32768`) |
| Level 3 | roughly 23k tokens | at least 32k, more if your machine allows |

The build script measures sizes as bytes / 4 and refuses to exceed these budgets; run `python scripts/build_runfiles.py --check` in the kit folder to see current sizes. Every RUNFILE asks the model to quote its first and last headings before it starts. If it cannot quote both, the file was cut off: raise the context length and paste it again.

A larger context uses more memory. If the model will not load, use a smaller model, or a frontier model for the interview.

The settings below are general knowledge about these servers, not from the kit's research, and were not tested by the kit. Check your version's docs.

### Ollama

Ollama's default context is small (a few thousand tokens in past versions; it depends on version and hardware). Three ways to raise it:

1. **A Modelfile.** Works for every client, including tools that call the `/v1` OpenAI-compatible endpoint, which has no per-request context option:

   ```text
   FROM qwen2.5:14b
   PARAMETER num_ctx 16384
   ```

   ```sh
   ollama create qwen2.5-14b-16k -f Modelfile
   ollama run qwen2.5-14b-16k
   ```

   Then use the new model name everywhere.

2. **Per request, on the native API:** add `"options": {"num_ctx": 16384}` to the JSON body of `/api/chat` or `/api/generate`. Inside `ollama run`, type `/set parameter num_ctx 16384`.
3. **Server-wide:** `OLLAMA_CONTEXT_LENGTH=16384 ollama serve`. Unverified: this env var exists only in recent versions; check `ollama serve --help` or the Ollama FAQ.

Strix needs `num_ctx` of at least 16k to 32k with thinking off (from Strix's docs).

### LM Studio

Set "Context Length" in the model's load settings before loading it. It is fixed while the model is loaded; reload to change it. Recent versions also accept `lms load <model> --context-length 16384` (unverified; check `lms load --help`).

## Base URLs

Run one local server.

| Server | Native API | OpenAI-compatible API |
| --- | --- | --- |
| Ollama | `http://localhost:11434` | `http://localhost:11434/v1` |
| LM Studio | - | `http://localhost:1234/v1` |

Check what is running with the kit's probe script:

```sh
bash levels/2-starter-tools/installers/check-local-model.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File levels\2-starter-tools\installers\check-local-model.ps1
```

Or by hand:

```sh
curl http://localhost:11434/api/tags      # Ollama: lists pulled models
curl http://localhost:1234/v1/models      # LM Studio: lists loaded models
```

## The `/v1` suffix: the most common failure

Each tool wants a different URL for the same Ollama server.

| Tool | Ollama URL | Has `/v1`? | OpenAI-compatible (LM Studio) URL |
| --- | --- | --- | --- |
| LangExtract | `http://localhost:11434` | **No** | `http://localhost:1234/v1` (untested) |
| graphify (headless) | `http://localhost:11434/v1` | **Yes** (default) | `http://localhost:1234/v1` |
| Open Code Review | `http://127.0.0.1:11434/v1` | **Yes** | `http://localhost:1234/v1` (undocumented) |
| Strix | `http://localhost:11434` | **No** | `http://localhost:1234/v1` |

**Warning:** LangExtract and graphify both read `OLLAMA_BASE_URL`, but LangExtract wants it without `/v1` and graphify with it. Do not set `OLLAMA_BASE_URL` globally in your shell profile; set it per tool, per command. The installers write per-tool examples to `./.pmkit/env/<tool>.env.example`.

## Per-tool settings

### Tools that use only the host agent's model

ICM, OKF (the spec), Procedural-Graphs-style pitfalls and Archify make no model calls of their own. If your agent runs a local model, they use it.

- Archify: small models may fail its JSON validation (undocumented). Set `ARCHIFY_UPDATE_CHECK_DISABLED=1` to stop its only outbound request.
- ICM: the paper tested only Claude models; icm-template reports no testing. Other agents need `AGENTS.md` or the instruction file pasted in.

### LangExtract

Ollama (native):

```python
import langextract as lx
result = lx.extract(
    text_or_documents=text,
    prompt_description="...",
    examples=examples,
    model_id="gemma2:2b",                 # or a larger model
    model_url="http://localhost:11434",   # no /v1
)
```

Or set `OLLAMA_BASE_URL=http://localhost:11434` (read in the code, not documented in the README).

LM Studio or another OpenAI-compatible server (untested):

```python
config = lx.factory.ModelConfig(
    model_id="<model name>",
    provider="openai",
    provider_kwargs={"base_url": "http://localhost:1234/v1", "api_key": "lm-studio"},
)
```

Pass `api_key` explicitly; the env-var lookup only matches `gpt*` model ids.

Caveats:

- Ollama has JSON mode only, not strict schema. Leave `fence_output` and `use_schema_constraints` unset.
- Recall drops with small models.
- The core install still pulls `google-genai` and `google-cloud-storage`.

### graphify

Code-only needs no model: `GRAPHIFY_BACKEND=none`.

Headless CLI with Ollama (`OLLAMA_HOST` is also honoured):

```sh
GRAPHIFY_BACKEND=ollama
OLLAMA_BASE_URL=http://localhost:11434/v1     # default, with /v1
OLLAMA_MODEL=qwen2.5-coder:7b                 # default
```

OpenAI-compatible (LM Studio):

```sh
GRAPHIFY_BACKEND=openai          # unverified value: check graphify --help
OPENAI_BASE_URL=http://localhost:1234/v1
OPENAI_MODEL=<model name>        # GRAPHIFY_OPENAI_MODEL takes precedence
```

Or register an endpoint with `graphify provider add` (stored in `~/.graphify/providers.json`).

Caveats:

- **The `/graphify` skill ignores `GRAPHIFY_BACKEND`.** In skill mode it uses Gemini if `GEMINI_API_KEY` or `GOOGLE_API_KEY` is set, otherwise the host agent's model. For strict local use, unset the Google keys and run the headless CLI, or stay code-only.
- graphify allows LAN hosts with a warning. Make sure the URL is `localhost`.

### Open Code Review

Simplest local route: **delegation mode** with a host agent that already runs a local model. OCR makes no LLM call in that mode.

Own-LLM mode with Ollama, as a custom provider:

```sh
ocr config set provider ollama
# then set, per the upstream configuration doc:
#   custom_providers.ollama.url      http://127.0.0.1:11434/v1
#   custom_providers.ollama.protocol openai
#   custom_providers.ollama.model    qwen3:32b
#   custom_providers.ollama.api_key  ollama     (any non-empty placeholder)
```

The exact `ocr config set` key syntax is unverified. Check `pages/src/content/docs/en/configuration.md` in the upstream repo.

Or by env:

```sh
OCR_LLM_URL=http://127.0.0.1:11434/v1
OCR_LLM_TOKEN=ollama
OCR_LLM_MODEL=qwen3:32b
OCR_LLM_PROTOCOL=openai
OCR_LLM_TIMEOUT=900          # default 300 s; raise for slow local models
```

Caveats:

- The model must emit native tool calls: qwen3 works, deepseek-r1 fails with "No tool calls parsed".
- LM Studio is undocumented.
- If nothing is configured, OCR falls back to `ANTHROPIC_*` env vars.

### Strix (Level 3 only, Service layer)

```sh
STRIX_LLM=ollama/<model>
LLM_API_BASE=http://localhost:11434      # or OLLAMA_API_BASE; no key needed
```

LM Studio or other OpenAI-compatible:

```sh
STRIX_LLM=openai/<model>
LLM_API_BASE=http://localhost:1234/v1
```

Caveats:

- Ollama needs `num_ctx` of at least 16k to 32k (see [Context length](#context-length-set-it-before-you-paste-a-runfile)) and thinking off.
- llama.cpp needs `--jinja`. vLLM needs `--enable-auto-tool-choice --tool-call-parser ...`.
- Temperature 0.2 to 0.6.
- Strix's own docs say models under 70B "struggle". Do not trust a small model's result as a security sign-off.

### Not supported or not needed

- OKF reference agent: Gemini only. A local model would need code changes; out of scope for the kit.
- workflow-graph: no model.

## Smoke tests

Run one tiny test per tool before the project relies on the local route. These are suggestions from the research; commands marked unverified have not been run by the kit.

| Tool | Smoke test | Pass looks like |
| --- | --- | --- |
| Ollama / LM Studio | `curl http://localhost:11434/api/tags` or `curl http://localhost:1234/v1/models` | A JSON list that includes your model |
| LangExtract | Run the Python snippet above on one sentence with one example (unverified) | At least one extraction with a character interval |
| graphify | `GRAPHIFY_BACKEND=ollama graphify extract <tiny-folder>` on a folder with one markdown file (unverified flags; check `graphify --help`) | A `graphify-out/` folder with `graph.json` |
| Open Code Review | Make a one-line change in a scratch git repo, then `ocr review` with the `OCR_LLM_*` vars set (unverified) | A review result, not "No tool calls parsed" |
| Strix | Only against a local app you own: `strix -n --target ./app --scan-mode quick --max-budget 1` (unverified that a local model completes a run) | A run folder under `strix_runs/` and no tool-call errors |

If a test fails, check the `/v1` table first.

## Hardware: what we can and cannot say

- Model size and context length both drive memory use. The kit has not benchmarked any hardware and gives no untested RAM or GPU figures.
- Tools that need tool calls (OCR own-LLM mode, Strix, coding agents) are unreliable below about 30B parameters. Strix's docs say under 70B "struggle".
- The local models Strix recommends (DeepSeek V3.1, Devstral 2) are far beyond consumer hardware (general knowledge, not from the Strix repo).
- Small models such as `gemma2:2b` (LangExtract) or `qwen2.5-coder:7b` (graphify default) run on modest machines (general knowledge, not tested by the kit) but give lower quality. Check their output before you trust it.
- If your machine cannot run a model large enough for a task, use a frontier model for it, or skip it. Do not quietly lower the bar.

## Record your choice

Write the model, server and context length for each task type in the "Model routing" section of `SETUP_DECISIONS.md`. Log a change with:

```sh
python .pmkit/pmkit.py log --type DECIDE --summary "Route LOG/STATUS drafting to local Ollama model"
```
