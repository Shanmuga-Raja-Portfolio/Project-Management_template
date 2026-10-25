<!-- What changed and why, in a few lines. Link upstream sources for new facts. -->

- [ ] Every commit is signed off (`git commit -s`, DCO)
- [ ] Code of Conduct read and followed
- [ ] New facts link to an upstream source; anything unconfirmed is marked "unverified"
- [ ] No benchmarks, star counts, marketing words or emoji
- [ ] Tool cards keep the template headings, "What it does NOT do", network calls, files touched and a "Checked:" date
- [ ] `catalog/README.md`, `CREDITS.md`, `interview/MAPPING.md` and triggers updated where needed
- [ ] RUNFILEs regenerated; `python scripts/build_runfiles.py --check` passes
- [ ] `python .pmkit/pmkit.py check` passes inside `template/` (`<fill in` warnings are expected)
- [ ] `.sh` and `.ps1` scripts still match and were dry-run tested (if changed)
- [ ] Relative links work

The full checklist is in [CONTRIBUTING.md](../CONTRIBUTING.md#pr-checklist).
