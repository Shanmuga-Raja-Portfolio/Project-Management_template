# LangExtract

## One-liner

A Python library that uses an LLM to pull structured records out of text, with character offsets pointing back to where each one came from.

## Layer

**Tool** with a local Ollama model. It becomes a **Service** when it uses a cloud backend (Gemini, OpenAI).

Available at Level 2 (installer) and Level 3.

## What it does

- You call `lx.extract(text, prompt, examples, model_id)`. The few worked examples set the output shape.
- Each extraction carries character offsets into the source text ("source grounding"), so a person can check it.
- Items it cannot align get `char_interval=None`. Not every extraction is guaranteed an offset.
- Long documents are chunked (`max_char_buffer`), processed in parallel (`max_workers`) and can be run more than once (`extraction_passes`).
- Saves results as JSONL. `lx.visualize()` writes a self-contained HTML page that highlights each extraction in the source.
- Structured output: Gemini and OpenAI (`response_format`). Ollama has JSON mode only, not strict `output_schema`.

## What it does NOT do

- It is a library you call from Python. It is not a CLI, MCP server, workflow or memory system.
- It is not for Q&A or RAG.
- It is not for code analysis.
- It does not make medical or other high-stakes decisions. Health use is also subject to separate terms (see Cost & risk).
- It does not enforce a strict schema on Ollama.
- It is not a document-compliance pipeline. It has no OCR, page mapping or sign-off workflow. The kit does not cover those yet (planned for v0.2).

## Use when (triggers)

- You must turn a pile of text (interviews, contracts, requirements, papers, notes) into checkable records with source spans.
- The agent has been making up facts, and you need extractions you can trace back to the source.

## Skip when

- There is little text.
- The job is question answering or retrieval.
- You need relationships for navigation (see [graphify.md](graphify.md)) or memory for later recall (use `knowledge/` with [OKF](okf.md), plus `DECISIONS.md`).

## Install

Requires Python 3.10+. Use a virtual environment.

```bash
python -m venv .pmkit/venv-langextract
# POSIX:   . .pmkit/venv-langextract/bin/activate
# Windows: .pmkit\venv-langextract\Scripts\Activate.ps1
pip install langextract           # extras: [openai], [all] (all only adds openai)
```

The core install pulls `google-genai` and `google-cloud-storage` even if you only use Ollama.

The Level 2 installer is in [`levels/2-starter-tools/installers/`](../levels/2-starter-tools/installers/README.md) (`langextract.sh` / `langextract.ps1`). It asks before creating the venv in `./.pmkit/venv-langextract`.

Version seen at check: 1.7.1 (pyproject). The installer installs the latest release by default and prints the exact version. To pin one, pass `--version <v>` (`-Version <v>` in PowerShell), or by hand: `pip install langextract==<v>`. Record the version you install in `SETUP_DECISIONS.md` under "Installed tools".

## Files/settings it touches

- The Python environment you install it into (the kit suggests `./.pmkit/venv-langextract`).
- Output files your script writes: JSONL via `lx.io.save_annotated_documents`, HTML via `lx.visualize()`.
- It can read `LANGEXTRACT_API_KEY` from a `.env` file. Do not commit `.env` files.

## Network calls & data leaving the machine

- **Ollama on localhost**: text stays on the machine.
- **Gemini or OpenAI**: the documents you extract from are sent to that provider.
- Token cost and data sent grow with document length times `extraction_passes`.
- Telemetry: not documented upstream (unverified).

## API keys

- Ollama: none.
- Gemini: `GEMINI_API_KEY`, then `LANGEXTRACT_API_KEY`. Vertex AI uses service-account auth via `language_model_params`.
- OpenAI (`gpt*` model ids): `OPENAI_API_KEY`, then `LANGEXTRACT_API_KEY`.
- Azure OpenAI: not documented upstream (unverified). It may work through the OpenAI provider with `base_url` set to your Azure endpoint, using the same `ModelConfig(provider="openai", provider_kwargs={...})` pattern shown below. Azure deployment names and API versions may need more than that. If your organisation allows only Azure, test this on a non-sensitive sample before you rely on it, and record the result in `SETUP_DECISIONS.md`.
- If more than one is set, it uses the first and warns.
- Env lookup matches only by model-id pattern. For an OpenAI-compatible server with a non-`gpt` model id, pass `api_key` explicitly in `provider_kwargs`.
- This kit never asks for or stores keys.

## Local model route (exact env vars)

Ollama, native API. **No `/v1` suffix.**

```python
import langextract as lx
result = lx.extract(
    text_or_documents=text,
    prompt_description=prompt,
    examples=examples,
    model_id="gemma2:2b",                  # or a larger model
    model_url="http://localhost:11434",    # or set OLLAMA_BASE_URL
)
```

Env alternative: `OLLAMA_BASE_URL=http://localhost:11434` (read in the code; the README does not document it).

Leave `fence_output` and `use_schema_constraints` unset with Ollama.

LM Studio or another OpenAI-compatible server (untested):

```python
config = lx.factory.ModelConfig(
    model_id="<name>",
    provider="openai",
    provider_kwargs={"base_url": "http://localhost:1234/v1", "api_key": "lm-studio"},
)
result = lx.extract(
    text_or_documents=text,
    prompt_description=prompt,
    examples=examples,
    config=config,                         # argument name unverified; check the upstream README
)
```

Recall drops with small models. Smoke test: one sentence, one example, check that an extraction comes back with a `char_interval`.

More in [guides/local-models.md](../guides/local-models.md).

## Privacy-safe settings

```bash
OLLAMA_BASE_URL=http://localhost:11434
# Do not set GEMINI_API_KEY, LANGEXTRACT_API_KEY or OPENAI_API_KEY
# in the project environment when documents must stay local.
```

Make sure `model_url` / `base_url` points at `localhost`.

## Conflicts/overlaps

- **graphify semantic pass**: running both over the same corpus pays for two LLM passes and gives two unreconciled results. Pick one per corpus. LangExtract is the one for auditable records with source spans.
- **OKF knowledge files**: extracted records are machine output. Mark them as machine-generated (`generated{by,at}`), not `verified`, until a person checks them.

See [guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md).

## Cost & risk

- Setup: one pip install. Light.
- Cloud cost scales with corpus size times passes. Avoid many passes on large corpora with a small budget.
- Quality depends on the model and the examples. Check a sample by hand before relying on it.
- License Apache-2.0. Health-related use is also subject to the Health AI Developer Foundations Terms of Use.
- The README says it is not an officially supported Google product.

## Upstream link

<https://github.com/google/langextract> (Apache-2.0)

## Checked: 2026-10-17

## Unverified

- LM Studio, vLLM and LiteLLM through the OpenAI-compatible route.
- Azure OpenAI through the OpenAI provider's `base_url`.
- The exact `lx.extract` argument that takes a `ModelConfig` (shown above as `config=`).
- Telemetry: none documented upstream; the source was not checked for it.
- Grounding quality with non-Gemini models.
- Release dates and star or commit counts.
- The citation block says 1.6.0 while pyproject says 1.7.1.
