# Level 2 installers

One script per light tool, in two versions with the same steps. Pick the one for your shell:

- `<tool>.sh` for macOS and Linux (bash), or Git Bash / WSL on Windows.
- `<tool>.ps1` for Windows PowerShell 5.1 and later.

> This kit recommends third-party tools. It does not own or vouch for them. Read each tool card and the upstream README before installing. Check what leaves your machine. Security testing tools (e.g. Strix) may only be used on systems you own or have written permission to test. No warranty (MIT).

| Script | Installs | Needs | Card |
|---|---|---|---|
| `archify` | Archify agent skill (`npx skills add tt-a1i/archify -g`) | Node.js 18+ with npx | [archify.md](../../../catalog/archify.md) |
| `graphify` | graphify CLI, PyPI package `graphifyy`, code-only mode | uv (or pipx as fallback); Python 3.10+ | [graphify.md](../../../catalog/graphify.md) |
| `open-code-review` | Open Code Review CLI (`ocr`) from npm, delegation mode | npm, and git 2.41+ | [open-code-review.md](../../../catalog/open-code-review.md) |
| `langextract` | LangExtract Python library, in a project venv | Python 3.10+ | [langextract.md](../../../catalog/langextract.md) |
| `check-local-model` | Nothing. Probes Ollama and LM Studio on localhost | curl (bash) or nothing extra (PowerShell) | [local-models.md](../../../guides/local-models.md) |

Service-layer tools (Strix) have no installer. They are manual, guided steps at [Level 3](../../3-interview/README.md).

## How to run

Run from **your project root**; paths in the env examples are relative to it. A dry run first is a good habit.

```bash
cd /path/to/your-project
bash /path/to/pmkit/levels/2-starter-tools/installers/graphify.sh --dry-run
bash /path/to/pmkit/levels/2-starter-tools/installers/graphify.sh
```

```powershell
cd C:\path\to\your-project
powershell -NoProfile -ExecutionPolicy Bypass -File C:\path\to\pmkit\levels\2-starter-tools\installers\graphify.ps1 -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File C:\path\to\pmkit\levels\2-starter-tools\installers\graphify.ps1
```

`-ExecutionPolicy Bypass` applies to that one command only and does not change your system setting. Please read the script first if you have not.

### Flags

| bash | PowerShell | Effect |
|---|---|---|
| `--dry-run` | `-DryRun` | Print every step, command and file content. Change nothing. |
| `--yes` | `-Yes` | Accept the steps without asking. For scripted use. |
| `--version <v>` | `-Version <v>` | Install exactly that version (graphify, Open Code Review, LangExtract). For Archify, check the installed version instead. A leading `v` is dropped. |
| `--help` | `-Help` | Show usage. |

- `--yes` never answers the two optional graphify integration steps (`graphify install`, `graphify hook install`); they always need a typed yes. `--dry-run --yes` shows them as skipped.
- For LangExtract, `--yes` means "use the venv". It never installs into your current Python.
- `--yes` answers this kit's prompts only. Called tools may ask their own: `npx` may ask "Ok to proceed?" before downloading the `skills` CLI, which may ask which agents to install for.
- An unknown option, or a version that is not a release number, exits with code 2 (bash and PowerShell). In PowerShell, `-Version` with no value is rejected by PowerShell itself (exit code 1).
- The PowerShell scripts judge each step by exit code only, so stderr progress text does not stop them when output is redirected (by an agent, an IDE task or CI).

## What every installer does

1. **Prints the plan first:** the tool, each step, exact commands, files and settings touched, network calls, and keys needed.
2. **Checks prerequisites** and says how to get missing ones. It never installs them itself.
3. **Asks y/N before each step.** The default is No. With no terminal to answer, every step is skipped.
4. **Never asks for or stores API keys.** It writes an example file, never a real `.env`.
5. **Writes a privacy-safe env example** to `./.pmkit/env/<tool>.env.example`, settings only. An existing file is left alone. Copy the lines you want into your shell or agent environment.
6. **Prints the exact installed version** for the "Installed tools" table of `SETUP_DECISIONS.md`, with the `--version` command that reinstalls it. If you passed `--version` and a different version is installed, it warns.

### Pinning versions

Without `--version`, you get the latest release. Several of these tools release every few days, so pin anything you want to reproduce (a second machine, a teammate, CI):

```bash
bash /path/to/pmkit/levels/2-starter-tools/installers/graphify.sh --version 0.9.92
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\path\to\pmkit\levels\2-starter-tools\installers\graphify.ps1 -Version 0.9.92
```

| Tool | What `--version 1.2.3` runs | Version seen at check (2026-10-17) |
|---|---|---|
| graphify | `uv tool install graphifyy==1.2.3` (or `pipx install graphifyy==1.2.3`) | 0.9.92 |
| Open Code Review | `npm i -g @alibaba-group/open-code-review@1.2.3` | 1.13.1 |
| LangExtract | `python -m pip install langextract==1.2.3` in the venv | 1.7.1 |
| Archify | No pin. Installs as usual, then checks the installed version; exits with code 3 if it differs | 3.1.0 |

If the tool is already installed, a package manager may keep the old version; check the output. To change versions, uninstall first ([Removing a tool](#removing-a-tool)).

## Tool by tool

### Archify

- **Step 1:** `npx skills add tt-a1i/archify -g`. The skills CLI picks the folder (Claude Code: `~/.claude/skills/`). The `skills` CLI itself is not pinned: npx fetches the latest from npm, and it may prompt you a second time.
- **Observed, not documented** (one Windows test run, 2026-10-17): `-g` put the skill in `~/.agents/skills/archify`, linked it into the skills folders of every agent the CLI found (Claude Code and several others), and added an entry to `~/.agents/.skill-lock.json`. Answer the CLI's agent question to limit this.
- **Pinning:** the skills CLI has no documented way to choose an older release, so `--version <v>` checks the installed `package.json` version and exits with code 3 if it differs. For an exact release, use the clone route in the upstream README with that release's tag (for example `v3.1.0`).
- **Step 2:** env example with `ARCHIFY_UPDATE_CHECK_DISABLED=1`. This stops Archify's only outbound request, an update-check GET that sends no project data.
- Archify makes no LLM calls; your agent writes the diagram JSON.
- The upstream README promotes discounted API reseller services. Archify does not need them; please do not route keys through them.

### graphify (code-only)

- **Step 1:** `uv tool install graphifyy`, or `pipx install graphifyy` if uv is missing (`graphifyy==<v>` with `--version`). Two y. Other `graphify*` packages are not affiliated.
- **Step 2:** env example with `GRAPHIFY_BACKEND=none` (no LLM backend, including the `claude -p` labelling fallback) and `GRAPHIFY_QUERY_LOG_DISABLE=1`.
- **Step 3, optional, separate prompt:** `graphify install` copies the skill to `~/.claude/skills/graphify/`, **appends a block to `~/.claude/CLAUDE.md`**, and writes a lock file under `~/.cache/graphify/skill-locks/`. It targets Claude Code unless you pass `--platform`. On Windows, bare install uses the `windows` variant, whose exact paths are unverified; check the output.
- **Step 4, optional, separate prompt, git repos only:** `graphify hook install` writes blocks into four git hooks (post-commit, post-checkout, post-merge, post-rewrite), adds `merge.graphify.*` to git config, and edits `.gitattributes`.
- If `graphify` is not on PATH yet (common right after a first `uv tool install`), steps 3 and 4 are skipped with a hint to run `uv tool update-shell` and open a new shell.
- **Warning:** the `/graphify` skill ignores `GRAPHIFY_BACKEND`. It uses Gemini if `GEMINI_API_KEY` or `GOOGLE_API_KEY` is set, otherwise your agent's model. For strictly local work, use the headless CLI: `graphify extract <folder>`.

### Open Code Review (delegation mode)

- **Step 1:** `npm i -g @alibaba-group/open-code-review` (`@<v>` with `--version`).
- **Step 2:** prints the commands to run inside Claude Code:

  ```text
  /plugin marketplace add alibaba/open-code-review
  /plugin install open-code-review@open-code-review
  ```

  Use `/open-code-review:delegate-review`: OCR makes no LLM call and needs no key. `/open-code-review:review` uses OCR's own LLM.
- **Step 3:** env example. Telemetry is off by default. A commented local route is included (Ollama at `http://127.0.0.1:11434/v1`, OpenAI protocol); the model must support native tool calls.
- **Warning:** if OCR's own LLM is not configured, it silently reuses `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_MODEL`.
- The script does not create `~/.opencodereview/config.json`.

### LangExtract

- **Step 1:** asks to create a venv at `./.pmkit/venv-langextract`. If you say no, it asks whether to install into your current Python. Keep the venv out of git: the kit's template `.gitignore` lists `.pmkit/venv-*/`; add that line to your own `.gitignore` if you have one.
- **Step 2:** `python -m pip install langextract` in the venv (`langextract==<v>` with `--version`). The core install also pulls `google-genai` and `google-cloud-storage`, even if you only use Ollama.
- **Step 3:** env example with `OLLAMA_BASE_URL=http://localhost:11434` (no `/v1` for LangExtract). Ollama gives JSON mode only, not a strict schema.

### check-local-model

- Sends one GET to `http://localhost:11434/api/tags` (Ollama) and one to `http://localhost:1234/v1/models` (LM Studio), 3 seconds each.
- Lists the models each reports and prints the per-tool base URLs.
- Installs and writes nothing. `--dry-run` makes no requests.

## After installing

1. Record the tool, exact version, date, trigger and env example path in the "Installed tools" table of `SETUP_DECISIONS.md` (format: [interview/OUTPUTS.md](../../../interview/OUTPUTS.md)).
2. If `LOG.md` exists, log it:

   ```bash
   python .pmkit/pmkit.py log --type TOOL-ADD --summary "Added Archify 3.x: handoff needs an architecture diagram" --files SETUP_DECISIONS.md
   ```

3. Set a revisit date, and re-check the card before upgrading.

## Removing a tool

If a tool did not pay off, remove it, delete `./.pmkit/env/<tool>.env.example`, and log a `TOOL-REMOVE` entry.

| Tool | Remove with |
|---|---|
| Archify | Delete the `archify` folder from your agent's skills folder. If it was installed under `~/.agents/skills/archify`, also delete the links to it in other agents' skills folders and its entry in `~/.agents/.skill-lock.json`. Check `npx skills --help` for a remove command first (unverified) |
| graphify | `uv tool uninstall graphifyy` (or `pipx uninstall graphifyy`). After step 3, delete `~/.claude/skills/graphify/` and the graphify block in `~/.claude/CLAUDE.md`. After step 4, remove the marked blocks from the four git hooks, the `merge.graphify.*` git config entries and the `.gitattributes` line. Check `graphify --help` for an uninstall command first (unverified) |
| Open Code Review | `npm uninstall -g @alibaba-group/open-code-review`, and remove the plugin in Claude Code |
| LangExtract | Delete `./.pmkit/venv-langextract` |

## Tested

On 2026-10-17:

- Every `.sh` passed `bash -n`, and every `.ps1` parsed with no errors under Windows PowerShell 5.1.
- Each installer ran in an empty folder with `--dry-run` / `-DryRun`: with and without a version (`v` prefix and `--version=` form included), with `--dry-run --yes --version`, and with no input (all steps skipped). None changed anything.
- A bad version, a missing value and an unknown option were each rejected.
- Version checks ran against stub tools (fake `uv`, `npm`, `npx`, `node`, `git`, `python` printing fixed versions): the pinned command was passed through, a mismatch warned, and Archify exited with code 3.
- Earlier rounds covered redirected stderr, graphify missing from PATH, a broken LangExtract venv and odd local-model replies.

Real installs were not part of the check. Upstream commands come from the tool cards, checked 2026-10-17.
