# Interview question bank

The canonical interview questions, read by the skill and the RUNFILEs. Ask only questions whose `Levels:` line includes the current level, one at a time, in id order ([CONDUCT.md](CONDUCT.md)). Skip a question when its "Skip if" holds; record the implied answer and say so. Every question changes the setup; [MAPPING.md](MAPPING.md) says how. No question asks about persona or the user's identity.

<!-- Format (scripts parse it): `### Qnn — title`, then on the next line `Levels:` with `L1`, `L2`, `L3`. No other headings between questions. -->

### Q01 — What is being produced
Levels: L1, L2, L3

- **Ask:** "What will this project produce: an app or other code, a website, a no-code automation, research, writing, data analysis, a work process, or a mix?"
- **Options:** code product · website (coded, or a site builder) · no-code app or automation · research · writing/content · data/analytics · ops/process · mixed
- **Why it matters:** Only code keeps the "Code" section of `RULES.md` and brings code tools in later. Research and data lean on knowledge notes (in a browser chat: one `SOURCES.md`). Site-builder and no-code projects are treated like writing.
- **Skip if:** the user already described the deliverable.

### Q02 — How the work runs over time
Levels: L1, L2, L3

- **Ask:** "Is this a one-off, a process you repeat (a weekly report), an ongoing product you keep improving, or a backlog with new items arriving regularly (monthly documents)?"
- **Options:** one-off · repeatable process · ongoing product · backlog + recurring intake · not sure yet
- **Why it matters:** A repeated process, or the handling of each new batch, can get stage folders. An ongoing product leans on a decision log instead.
- **Skip if:** Q01 made it clear. **If "not sure":** treat as one-off.

### Q03 — Duration
Levels: L1, L2, L3

- **Ask:** "Roughly how long will this run: days, weeks, or months or more?"
- **Options:** days · weeks · months+
- **Why it matters:** Days need the minimum. Weeks or more make a decision log worth it.
- **Skip if:** a timeframe was given, or Q02 = ongoing product (months+).

### Q04 — New or existing material
Levels: L1, L2, L3

- **Ask:** "Are you starting from nothing, or from existing material (code, papers, PDFs, documents, notes)? Roughly how much, and who made it?"
- **Options:** new · existing and small · existing and large · inherited (someone else made it)
- **Why it matters:** Kit files go next to existing material; nothing is moved or renamed. `PROJECT.md` notes where it lives. "Large": for code, tens of thousands of lines; for documents, more than you could reread in a day.
- **Skip if:** clearly an empty folder.
- **Follow-up (Level 2 and 3 only, existing code):** "Is it in git?" A "no" rules out code review tools for now. At Level 1 do not ask; note whether you can see a `.git` folder.

### Q05 — Solo, team, or handoff
Levels: L1, L2, L3

- **Ask:** "Is this just you, or a team? Will someone else take it over later?"
- **Options:** solo · team · solo now, handoff later
- **Why it matters:** When others work in the files, decision records and checked-by fields pay off.
- **Tie-break:** someone who only reads drafts (supervisor, client, editor) means "solo"; name them in `PROJECT.md` under Users. "Handoff later" only if they will take over the files.

### Q06 — Which AI tool
Levels: L1, L2, L3

- **Ask:** "Which AI tool will you use: an agent that works on your files (for example Claude Code, Cursor, Copilot, Codex, OpenCode, Aider, Gemini CLI), or only a chat window in a browser (ChatGPT, Claude.ai, Gemini)? Does anyone else use another?"
- **Options:** free text, may be several · browser chat window only
- **Why it matters:** Many agents read `AGENTS.md` directly; Claude Code gets a one-line `CLAUDE.md`. Browser chat only gets the light chat set, and the existing-conventions question is not asked.
- **Skip if:** running inside Claude Code and the user works alone. Record "Claude Code (implied)".

### Q07 — How much upkeep will you actually keep up?
Levels: L1, L2, L3

- **Ask:** "How much upkeep will you actually keep up? The minimum is a short status note after each session. Would you also keep a decision log (a short entry per choice worth remembering), a knowledge folder (notes on facts and sources, with who checked them), both, or neither?"
- **Options:** minimal · minimal + decision log · minimal + knowledge folder · both · full (both, plus stage folders for a repeated process)
- **Why it matters:** This caps everything else, tools included: each tool is upkeep too. At "minimal", no tool is suggested now; tools whose trigger holds go under "Triggers to revisit".
- **Skip if:** never skip.

### Q08 — Data sensitivity
Levels: L1, L2, L3

- **Ask (Level 1):** "Does this include personal or confidential data? May it be sent to a cloud AI service?"
- **Options (Level 1):** no, cloud is fine · approved enterprise vendor only (for example Azure, Bedrock, Vertex) · nothing may leave this machine · not sure
- **Ask (Level 2 and 3):** the same, and "Think separately about code, documents and personal data."
- **Options (Level 2 and 3):** the Level 1 options, plus "code may leave, documents may not"
- **Why it matters:** A restriction becomes a rule in `AGENTS.md` (browser chat, no `AGENTS.md`: under Constraints in `PROJECT.md`) and fills the Data line in `PROJECT.md`. At Level 2 and 3 it also removes or reconfigures tools.
- **If "not sure":** treat as "nothing may leave" until checked. Never skip. **Do not ask** for the data itself or any credentials.

### Q09 — API budget and local hardware
Levels: L2, L3

- **Ask:** "Do you have a budget for paid API calls: none, a small monthly cap, or not a concern? Do you have a local model server (Ollama or LM Studio) or a machine with a strong GPU or a lot of RAM?"
- **Options (budget):** none · small cap · not a concern
- **Options (hardware):** local server running · capable machine, nothing installed · no
- **Why it matters:** No budget means methods only, delegation modes, code-only modes, or a local model. Tools that need tool calls or agent loops are unreliable on small local models (roughly under 30B parameters).
- **Follow-up:** "Is it OK if a tool falls back to your Claude subscription (for example by calling `claude -p`)?" Some tools do this unless it is turned off.
- **Skip if:** the user already said "no budget" and "no local model". Record both.

### Q10 — Volume of existing text
Levels: L2, L3

- **Ask:** "How much existing text will the project work from: a little, a folder, or hundreds of files (interviews, contracts, specs, papers)?"
- **Options:** little · a folder · hundreds of files
- **Why it matters:** Hundreds of files are a trigger for structured extraction. A little text needs no extra tool.
- **Follow-up (if a folder or more):** "Do you need checkable records with the exact source passage, or just answers to questions?" Only the first is a reason for extraction.
- **Skip if:** Q01 is a code product with no document inputs.

### Q11 — What went wrong before
Levels: L2, L3

- **Ask:** "In earlier projects with AI, what went wrong? For example: it forgot context, wandered between tasks, made things up, reviews missed bugs, costs ran over, or different agents on the team gave different answers. Or nothing yet."
- **Options:** forgot context · wandered · made things up · missed bugs · cost overrun · agents on the team diverged · nothing yet · other (free text)
- **Why it matters:** Past failures are the best evidence for which fix to add first. "Nothing yet" is a valid answer and keeps the setup small.
- **Skip if:** the user has no earlier AI-assisted projects. Record "no prior experience".

### Q12 — Attack surface and authorisation
Levels: L3

- **Ask:** "Will this expose a web app or API (logins, payments, user data)? If yes: do you own it, or have written permission to test it?"
- **Options:** no attack surface · yes, owned or authorised in writing · yes, not authorised · not sure
- **Why it matters:** Security testing tools may only run against systems the user owns or has written permission to test. Without that, they are never recommended.
- **Skip if:** Q01 is research, writing, or ops with no exposed service.
- **Do not ask:** for target URLs, credentials, or test accounts during the interview.

### Q13 — How you will know it is done
Levels: L3

- **Ask:** "How will you know the work is done or good enough: tests, a rubric, a reviewer, a metric, or not defined yet?"
- **Options:** tests · rubric · named reviewer · metric · not defined
- **Why it matters:** A clear check allows stage audits and "keep a change only if it is not worse". With no check, the plan adds a human review step instead of any automation. The answer goes in `PROJECT.md` under "Done when".
- **Skip if:** the user already gave done criteria.

### Q14 — Does a human need to learn this
Levels: L3

- **Ask:** "Does anyone (not just the AI) need to learn and remember this material, for example new team members with a large vocabulary or API to absorb?"
- **Options:** no · yes, a few people · yes, ongoing onboarding
- **Why it matters:** A yes adds glossary concepts in `knowledge/` and an Onboarding section to `PROJECT.md` ([MAPPING.md](MAPPING.md) gives its text). No extra tool.
- **Skip if:** Q03 is "days" and Q05 is "solo".

### Q15 — Diagrams and audience
Levels: L3

- **Ask:** "Will anyone need diagrams of the system or workflow (for onboarding, handoff, a review meeting)? If so, when? Does the product already have a web UI that must show live pipeline or DAG status?"
- **Options (diagrams):** no · yes, simple · yes, a curated diagram for an audience (now, or by a date or milestone)
- **Options (web UI):** no · yes, must show DAG status
- **Why it matters:** Default is Mermaid in markdown. A curated audience diagram needed now may justify Archify; one needed later goes under "Add later" with its date. Only an existing web UI showing DAG status justifies workflow-graph.
- **Skip if:** Q01 has no system or process to draw.

### Q16 — Other tools you want to use
Levels: L3

- **Ask:** "Are there tools you already use or want to try that are not in the catalog?"
- **Options:** none · free text list
- **Why it matters:** Each named tool is checked with [the bring-your-own-tool guide](../guides/bring-your-own-tool.md): overlap with existing choices, conflicts, network calls, and a disclaimer. The user decides.
- **Skip if:** never skip at Level 3. "None" is a fine answer.

### Q17 — Plan only, or scaffold
Levels: L3

- **Order:** ask this FIRST at Level 3, before Q01, so the user knows from the start whether anything will be created.
- **Ask:** "Do you want a written plan only (what to use, why, and when to add more), or should I also create the files?"
- **Options:** written plan only · plan and scaffold
- **Why it matters:** **SETUP_PLAN rule:** "written plan only" writes `SETUP_PLAN.md` and nothing else; "plan and scaffold" writes `SETUP_DECISIONS.md` and the chosen files, and no `SETUP_PLAN.md`. Formats are in [OUTPUTS.md](OUTPUTS.md).
- **Skip if:** the user already said which.
