# Using the kit in a browser chat window

This page is for you if you work in ChatGPT, Claude.ai, Gemini or a similar browser app, where the model cannot read or write files on your computer. You need much less than an agent setup: three small files you paste in.

## What you need

| File | What it holds | How often it changes |
| --- | --- | --- |
| `PROJECT.md` | Goal, who it is for, what is in and out of scope, how you will know it is done, constraints, risks | Rarely, when the plan changes |
| `STATUS.md` | Now, Next, Blocked. A few lines each. | Every session. You replace the whole file. |
| `RULES.md` | Short working rules for the model, such as "do not invent sources or citations" and "report only evidence". Keep the "General" and "Documentation" sections; delete "Agent" and "Code", which are for tools that work on your files. Edit or cut freely. | Rarely |

Optional:

- A short `SETUP_DECISIONS.md` recording what you chose and why.
- For research or writing that relies on sources, a `SOURCES.md`: one line per source (what it is, where to find it, why it matters). It stands in for the `knowledge/` folder agent setups use.

If the project includes personal or confidential data, write that rule in the "Constraints" section of `PROJECT.md`, for example "Do not paste client names into the chat".

You do not need `AGENTS.md`, adapters, `.pmkit/`, a log, a knowledge folder or the kit's checker (`pmkit.py check`).

## Getting the files

Pick one:

- **Short interview.** Paste [levels/1-starter/RUNFILE.md](../levels/1-starter/RUNFILE.md) into a new chat. When it asks which tool you use, say "browser chat window only". You get `PROJECT.md`, `STATUS.md`, `RULES.md` and a short `SETUP_DECISIONS.md`. Then ask it to help you fill in `PROJECT.md`; that usually takes two or three more messages.
- **Copy the blanks.** Copy [template/PROJECT.md](../template/PROJECT.md), [template/STATUS.md](../template/STATUS.md) and [template/RULES.md](../template/RULES.md), and replace each `<fill in ...>` placeholder yourself or with the model's help. In `RULES.md`, delete the "Agent" and "Code" sections.

**Getting a file from GitHub** needs no git or account. Open the file on GitHub, then either click **Raw** and copy the plain text, or use the **Copy raw file** (two overlapping squares) or **Download raw file** (down arrow) button at the top right of the file view. Button names and icons can change.

## Saving a file the model gives you

The model prints each file inside a box (a fenced code block).

1. Use the box's copy button, or select the text inside it. If you select by hand, leave out the fence lines (three backticks or tildes).
2. Paste into a plain-text editor: Notepad on Windows, TextEdit on macOS (Format > Make Plain Text first), or any code editor.
3. Save with the exact name, for example `STATUS.md`. On Windows, set "Save as type" to "All files" so it does not become `STATUS.md.txt`. Use UTF-8 if asked.
4. Keep the project's files in one folder.

You can also keep the files only in your chat app (next section), but a local copy is a good backup.

## Keeping the files in your chat app

Some apps let you group chats and attach files every chat in the group can see: Projects in ChatGPT, Projects in Claude.ai, Gems in Gemini. **We have not tested these steps, and the apps change often. Check your app's current UI and help pages.** The general idea:

1. Create a project (or Gem) for this piece of work.
2. Add `PROJECT.md`, `STATUS.md` and `RULES.md` as files, or paste them into the project's instructions or knowledge area. `RULES.md` fits well in the instructions, because it applies to every chat.
3. Start each new chat about this work inside that project.

Two things to know:

- **Uploaded files are copies.** When `STATUS.md` changes, replace the project's copy, or the model reads an out-of-date status.
- **Uploading sends the files to the app's provider.** For personal or confidential data, check what your plan and organisation allow first. If unsure, keep that data out of the files.

## Each session

**At the start**, paste `STATUS.md`, plus `RULES.md` and `PROJECT.md` if the chat has no copy. If they are stored in the project, say "Read RULES.md, PROJECT.md and STATUS.md first". Then say what you want to do today.

**At the end**, ask:

> Give me an updated STATUS.md as one markdown block, with the same three sections: Now, Next, Blocked. Keep each section to a few lines. Put today's date on the "Last updated" line.

Save it over your old `STATUS.md`, and replace the copy in your chat project if you keep one. When the goal or scope changes, ask for an updated `PROJECT.md` the same way.

## Limits

- The model only knows what you paste or upload in that chat or project.
- It may fill gaps with guesses. If it says something about your project that is not in the files, ask where it got it.
- In a very long chat it may lose early details. Start a fresh chat with `STATUS.md`.

## If you later use an agent on a folder

If you move to a tool that works on a folder of files (for example Claude Code, Cursor or Copilot in an editor), put your files in the project folder and run the Level 1 interview again. It keeps what you have and adds only what the new setup needs. See [START-HERE.md](../START-HERE.md).
