# Contributing

Thank you for helping. This kit is only useful while it stays accurate, short and plain, so please read this page before you open a pull request.

## Ground rules

- **Every fact needs a source.** Link the upstream repo, docs or code in your PR. If you cannot confirm something, mark it "unverified".
- **Say what is untested.** If you did not run it, say so.
- **No popularity numbers.** No benchmarks, star counts or download counts.
- **No marketing words or emoji.** No "supercharge", "unlock", "revolutionary", "10x", "second brain" or "OS" language.
- **No upsell.** No affiliate links, paid courses, key resellers or referral codes.
- **Plain English.** Short sentences. Say what a thing does and what it does not do.
- **Sign off your commits (DCO).** No CLA, ever — your contribution stays yours. Run `git commit -s` so the commit carries a `Signed-off-by:` line certifying you wrote it or may submit it under this project's license. CI checks for it.

## Adding a tool card

1. Copy [catalog/_card-template.md](catalog/_card-template.md) to `catalog/<tool-name>.md` (lowercase, hyphens).
2. Fill in every field, in order. A PR missing any of these will not be merged:
   - **What it does NOT do.** Be specific. It is often the most useful line on the card.
   - **Network calls & data leaving the machine.** Every outbound call you know of, including update checks and telemetry, and whether each is on by default.
   - **Files/settings it touches**, including anything outside the project (home directory config, git hooks, git config, editor instruction files).
   - **API keys**, plus any env vars it reads silently (for example, another tool's keys).
   - **Local model route** with exact env var names, or "none".
   - **Privacy-safe settings.**
   - **Conflicts/overlaps** with existing cards. See [guides/overlaps-and-conflicts.md](guides/overlaps-and-conflicts.md).
   - **Checked: YYYY-MM-DD**, the date you checked upstream.
   - **Unverified**: anything you could not confirm. Write "none" only if that is true.
3. Keep the template's `##` headings exactly as they are. `scripts/build_runfiles.py` copies these sections into the Level 2 and 3 RUNFILEs by heading, and a renamed heading drops out: "One-liner", "What it does NOT do", "Use when (triggers)", "Skip when", "Install", "API keys", "Local model route (exact env vars)", "Privacy-safe settings", "Conflicts/overlaps", "Checked".
4. Pick a layer: Method, Tool or Service. Anything that needs a database, Docker, API keys or a running service, or that carries active risk, is Service. Layers are not Levels; a level is how long the interview is.
5. If the tool has an installer, it must accept `--version <v>` (`-Version <v>` in PowerShell) to pin a version, or to check the installed version if the tool cannot be pinned. With no version, it installs the latest, prints the exact version, and asks the user to record it under "Installed tools" in `SETUP_DECISIONS.md`.
6. Add a row to [catalog/README.md](catalog/README.md) and a line to [CREDITS.md](CREDITS.md) with the upstream link and license.
7. If the tool changes a recommendation, update [interview/MAPPING.md](interview/MAPPING.md) and the triggers in [guides/adding-tools-mid-project.md](guides/adding-tools-mid-project.md), with at least one "skip when" case. A trigger must hold at setup time; anything needed only later (for example at handoff) goes under "Add later" with a date or milestone.
8. Regenerate the RUNFILEs (see [Generated files](#generated-files)).

Security testing tools must say they may only be used on systems you own or have written permission to test.

## Changing the interview

- A question earns its place only if a different answer changes the setup. Explain that change in the PR.
- Never add questions about persona, naming the assistant or similar. The interview is about the project.
- Never add a step that asks for secrets or API keys.
- Keep the `### Qnn — title` heading and the `Levels: ...` line on every question. The build script reads them.
- [interview/MAPPING.md](interview/MAPPING.md) has top-level `##` sections whose titles start with "All levels", "Level 1", "Level 2" or "Level 3". A level's RUNFILE gets the "All levels" sections plus its own and those of lower levels. Put each rule in the lowest level that asks the questions it uses. A "Level 1" section must not name Level 2 or 3 tools, or questions Level 1 does not ask.
- Use words newcomers know: "upkeep" for how much maintenance the user will keep up, and Method, Tool and Service for the layers, never numbers.

## Changing the starter folder

- Keep `template/` small. Every file needs a reason someone deleting it would understand.
- `AGENTS.md` is the one canonical instruction file. Adapters such as `CLAUDE.md` are generated from it. Do not add another root instruction file.
- `RULES.md` holds the working rules and is in every minimal set. `AGENTS.md` routes to it first and holds only mechanics (how to update STATUS, LOG, DECISIONS, knowledge, tools, checks). Never repeat a rule in both.
- `RULES.md` has four sections, numbered straight through: General, Documentation, Agent, Code. The interview and scripts may delete a whole section (Agent and Code for a chat-window set, Code for non-code projects) but never rewrite a rule. If you add, remove or renumber a rule, update every file that cites a section or rule number (`interview/`, `skill/project-setup/SKILL.md`, `scripts/build_runfiles.py`, the READMEs and guides), then rebuild the RUNFILEs. Rules say "the project's decision record", not a file name, so they work with `DECISIONS.md` or existing ADRs.
- A template line that only makes sense when an optional file exists ends with a marker such as `<!-- needs: DECISIONS.md -->` or `<!-- needs: knowledge/ -->` (a trailing `/` means a folder). `pmkit.py prune` removes those lines when the file is missing; `pmkit.py check` warns about them.
- `.pmkit/adapters.txt` ships with nothing enabled. The interview turns adapters on.

## Generated files

The level RUNFILEs (`levels/*/RUNFILE.md`) are generated, so please do not edit them by hand. Edit the sources in `interview/`, `catalog/`, `guides/` or `template/`, then run:

```bash
python scripts/build_runfiles.py
```

Each RUNFILE has a size budget, measured as bytes / 4 (roughly tokens): Level 1 at most 7,500, Level 2 at most 15,000, Level 3 at most 23,000. `--check` fails and prints the sizes when one is over. Level 1 must fit a local model with a 16k context. In user-facing docs, say "roughly" (for example "roughly 7k tokens"), since bytes / 4 is an estimate.

## Checks before you open a PR

Run both from the repo root. They need only Python 3.8 or newer and its standard library.

```bash
python scripts/build_runfiles.py --check
cd template && python .pmkit/pmkit.py check
```

On Windows PowerShell:

```powershell
python scripts\build_runfiles.py --check
Push-Location template; python .pmkit\pmkit.py check; Pop-Location
```

Inside `template/`, warnings about `<fill in` placeholders are expected. Any other warning or error needs fixing.

If you change a `.sh` installer, update the matching `.ps1` too (and the other way round): same steps, same questions. PowerShell scripts must run on Windows PowerShell 5.1, so no `&&`, `??` or ternary operator.

## PR checklist

Copy this into your PR description.

```markdown
- [ ] Every commit is signed off (`git commit -s`, DCO); CI's sign-off check passes
- [ ] Every new fact links to an upstream source; anything unconfirmed is marked "unverified"
- [ ] No benchmarks, star counts, marketing words or emoji
- [ ] Tool cards include "What it does NOT do", network calls, files touched, and a "Checked:" date
- [ ] catalog/README.md and CREDITS.md updated (if a card was added)
- [ ] MAPPING.md / triggers updated if a recommendation changed
- [ ] Question headings, `Levels:` lines, MAPPING section titles and card headings kept in the format the build script reads
- [ ] Optional-file lines in template files carry a `<!-- needs: ... -->` marker
- [ ] No placeholder org names in URLs; repo links use https://github.com/Shanmuga-Raja-Portfolio/Project-Management_template
- [ ] Code of Conduct read and followed
- [ ] RUNFILEs regenerated; `python scripts/build_runfiles.py --check` passes (including size budgets)
- [ ] `python .pmkit/pmkit.py check` passes inside template/ (warnings about `<fill in` placeholders are expected there)
- [ ] .sh and .ps1 installers still match (if changed); dry-run tested
- [ ] Relative links work on GitHub
```

## Reporting errors

Tools change fast. If a card is out of date, please open an issue with the field, what it says now, what it should say, and a link to the evidence.

## License

By contributing, you agree that your contribution is released under the [MIT License](LICENSE).
