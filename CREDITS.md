# Credits

pmkit builds on other people's good work. This page names those projects, what we take from each, and their licenses.

- pmkit copies no code from these projects. It describes them on tool cards and, where noted, borrows ideas and conventions in its own words.
- Licenses are as recorded on 2026-10-17. Please check upstream for the current terms.
- pmkit is independent. See [Trademarks](#trademarks).

## Methods (ideas the starter folder is built on)

| Project | One honest line | License |
|---|---|---|
| [ICM - Interpretable Context Methodology](https://github.com/RinDig/Interpretable-Context-Methodology) (RinDig) | Folder and markdown conventions with numbered stages and stage contracts (Inputs / Process / Outputs). Our optional `stages/` folder follows this idea. Paper: [arXiv 2603.16021](https://arxiv.org/abs/2603.16021) (Jake Van Clief, David McDermott; CC BY 4.0). | MIT (Model Workspace Protocol Contributors) |
| [icm-template](https://github.com/ktnCodes/icm-template) (ktnCodes) | An implementation of ICM with Claude Code skills and generated adapters for other editors. Our "one canonical file plus generated adapters" pattern also appears here. | MIT |
| [OKF - Open Knowledge Format](https://github.com/GoogleCloudPlatform/open-knowledge-format) (GoogleCloudPlatform) | A spec for a knowledge folder of markdown files with YAML frontmatter. Our `knowledge/` folder uses OKF v0.2 frontmatter. The original link, [knowledge-catalog/okf](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf), is a frozen copy; the repo linked first is the maintained home. | Apache-2.0 |
| [Procedural Graphs: Self-Evolving Execution Structures for LLM Agents](https://arxiv.org/abs/2609.09153) (arXiv 2609.09153; Yuxing Lu, Yicheng Chen, Shanchan Wu, Sercan Ö. Arık) | A paper, with no released code. Our idea of adding condition / guidance / pitfalls to stage handoffs, grown from observed failures, comes from it. | arXiv non-exclusive distribution license (paper) |

## Tools described on cards

| Project | One honest line | License |
|---|---|---|
| [Archify](https://github.com/tt-a1i/archify) (tt-a1i) | An agent skill that turns typed JSON from your agent into validated, self-contained HTML diagrams. It makes no LLM calls itself. | MIT |
| [graphify](https://github.com/Graphify-Labs/graphify) (Graphify-Labs, PyPI `graphifyy`) | Builds a knowledge graph of a code or document folder. Code parsing is local; docs need an LLM pass. | Apache-2.0 (older parts also under MIT) |
| [Open Code Review](https://github.com/alibaba/open-code-review) (alibaba) | A Go CLI for LLM review of git diffs. Delegation mode lets your own agent do the review. | Apache-2.0 |
| [LangExtract](https://github.com/google/langextract) (google) | A Python library that pulls structured records out of text and records where in the source each one came from. | Apache-2.0 (plus Health AI terms for health use) |
| [Strix](https://github.com/usestrix/strix) (usestrix) | An autonomous penetration-testing CLI that runs in a Docker sandbox. Use it only on systems you own or have written permission to test. | Apache-2.0 (cloud tier is commercial) |
| [workflow-graph](https://github.com/google/workflow-graph) (google) | A web component that draws DAGs. It does not run workflows. Listed as a fallback. | Apache-2.0 |

## Third-party tools and licenses

pmkit bundles no third-party code, images, fonts or other files. Everything in this repository is pmkit's own work under its MIT license (see [LICENSE](LICENSE)). Nothing is copied from the papers; the Procedural Graphs paper's arXiv license does not allow reuse, so the kit only cites it.

The optional Level 2 installers do not contain these tools. Each one asks before it runs, then uses your own package manager to download the tool from its official source. Each tool is under its own license, not pmkit's:

| Tool | Fetched from | License |
|---|---|---|
| Archify (tt-a1i; Cocoon AI) | GitHub, via `npx skills add tt-a1i/archify -g` | MIT. Its bundled brand icons and font have their own terms (see its THIRD_PARTY_NOTICES.md) |
| skills CLI ([vercel-labs/skills](https://github.com/vercel-labs/skills)), used by the Archify installer | npm | MIT |
| graphify (Safi Shamsi and the Graphify contributors) | PyPI package `graphifyy` | Apache-2.0, some earlier parts MIT (see its NOTICE) |
| Open Code Review (Alibaba / open-code-review contributors) | npm package `@alibaba-group/open-code-review` | Apache-2.0 |
| LangExtract (Google LLC) | PyPI package `langextract` | Apache-2.0; health-related use is also subject to Google's Health AI Developer Foundations Terms of Use |

A few more things worth knowing:

- **Strix** (OmniSecure Inc., Apache-2.0) is described but never installed by pmkit. If you install it, use it only on systems you own or are authorized to test. Its cloud and enterprise products have their own terms.
- **workflow-graph and LangExtract** are Google projects that state they are not officially supported Google products.
- **AI providers:** Open Code Review, and LangExtract or graphify with cloud models, send your code or text to the AI model provider you configure. That provider's terms and privacy policy apply.
- **Common tools pmkit does not ship:** Python 3.8+, git, Node.js/npm, uv or pipx, curl, and optionally Ollama or LM Studio. pmkit's own scripts use only the Python standard library, bash or Windows PowerShell 5.1.

### Trademarks

All product and project names (including Google, Gemini, Alibaba, Strix, graphify, Archify, OpenAI, Anthropic, Claude, Ollama and LM Studio) are trademarks of their respective owners and are used only to identify those projects. pmkit is an independent community project. It is not affiliated with, endorsed by or sponsored by any of them.

## Research

The tool facts in this repo come from a research pass checked on 2026-10-17. Anything that could not be confirmed is marked "unverified" on its card. If you spot an error, please open an issue or PR (see [CONTRIBUTING.md](CONTRIBUTING.md)).
