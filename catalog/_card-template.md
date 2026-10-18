# Tool card template

Copy this file to `catalog/<tool>.md` and fill in every section. Keep the sections in this order. The same template is used when the LLM evaluates a tool you bring yourself (see [guides/bring-your-own-tool.md](../guides/bring-your-own-tool.md)).

Rules for filling it in:

- Only write facts you checked in the tool's own README, docs or source. Put everything else under **Unverified**.
- No star counts, no benchmarks, no marketing words. Say what the tool does in plain words.
- Name exact commands, file paths and env vars. "Configurable" is not an answer.
- If a section does not apply, write "None" or "Not applicable" and one line saying why. Do not delete the section.
- Write the date you checked the upstream. Tools change fast.

---

# <Tool name>

## One-liner

<One sentence: what it is, in plain words. Not what it promises.>

## Layer

<One of: **Method** (file conventions, zero install) / **Tool** (local install, writes files, no daemon) / **Service** (database, Docker, keys, network or active risk). If the layer depends on settings, say which setting moves it.>

<Which kit level may offer it: Level 1 (methods only), Level 2 (light tools via installers), Level 3 (everything, with warnings).>

## What it does

- <Concrete behaviour. Inputs, outputs, where outputs go.>

## What it does NOT do

- <Things the name or README suggests but the tool does not do.>
- <Claims that are prompt instructions, not guarantees.>

## Use when (triggers)

- <A concrete, observable event that justifies adding it. "The agent re-reads the same files every session" is a trigger. "Better context" is not.>
- <A trigger must hold now. Something needed only later (at handoff, at release) goes under "Add later" with a date or milestone, not into day-one setup.>

## Skip when

- <Situations where it costs more than it gives.>

## Install

```bash
<exact command(s)>
```

<Prerequisites with versions. Version seen at check. How to pin a version, if upstream documents it. Remind the user to record the installed version in SETUP_DECISIONS.md under "Installed tools".>

## Files/settings it touches

| Command | Writes |
|---|---|
| <command> | <every file, folder, hook, git config, settings file, home-directory path> |

## Network calls & data leaving the machine

- <Every outbound call: install downloads, update checks, telemetry, LLM calls. What data is sent and to whom.>
- <Defaults that leak or bill (fallbacks to other keys or subscriptions).>

## API keys

- <Which keys, in which mode. "None" if none. This kit never asks for or stores keys.>

## Local model route (exact env vars)

```bash
<EXACT_VAR=value lines, with or without the /v1 suffix as the tool requires>
```

<Caveats: model size, tool-call support, untested servers. Link [guides/local-models.md](../guides/local-models.md).>

## Privacy-safe settings

```bash
<env block that turns off telemetry, update checks and cloud fallbacks>
```

## Conflicts/overlaps

- <Which catalog tools do the same job. Which files both write. What to pick instead. Link [guides/overlaps-and-conflicts.md](../guides/overlaps-and-conflicts.md).>

## Cost & risk

- <Setup weight, token cost, money, maturity (age, release churn, single maintainer), security exposure.>

## Upstream link

<URL> (<license>)

## Checked: <YYYY-MM-DD>

## Unverified

- <Everything you could not confirm from the source.>

---

## Extra section for bring-your-own-tool only

Add this at the end when the card is for a tool the user asked for that is not in the catalog.

## Kit disclaimer

This card was written by an LLM during setup from the tool's public pages. It has not been reviewed by the kit maintainers. The kit does not own or vouch for this tool. Read the upstream README before installing. Check what leaves your machine. You decide whether to use it.
