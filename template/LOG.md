# Work log

Append-only. One line per entry, newest at the bottom. Never edit or delete old lines.

Optional for code kept in git, where the commit history records what was done. Keep it if you want one place for setup, tool and review entries.

Format:

```
- YYYY-MM-DD | TYPE | summary | files: a.md, b.md
```

Types: `CREATE`, `UPDATE`, `DECIDE`, `TOOL-ADD`, `TOOL-REMOVE`, `REVIEW`, `HANDOFF`.

Add an entry by hand.
Or run `python .pmkit/pmkit.py log --type UPDATE --summary "..." --files a.md,b.md` from the project root. <!-- needs: .pmkit/ -->

For TOOL-ADD, put the trigger and the revisit date in the summary.

## Entries
