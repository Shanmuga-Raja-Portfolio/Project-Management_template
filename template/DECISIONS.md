# Decisions

Append-only. Add new entries at the bottom. Never edit or delete an old entry. To change a decision, add a new one that says which entry it supersedes.

Add an entry by hand in the format below.
Or run `python .pmkit/pmkit.py decide --title "..." --why "..." --alternatives "..." --revisit "..."` from the project root. <!-- needs: .pmkit/ -->

Entry format:

```
## D-### (YYYY-MM-DD): <short decision>

- Decision: <what was decided>
- Why: <the reason, in one or two lines>
- Alternatives considered: <what else was on the table>
- Revisit when: <a concrete trigger or a date>
```

## Entries
