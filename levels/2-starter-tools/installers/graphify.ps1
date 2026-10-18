<#
.SYNOPSIS
  pmkit Level 2 installer: graphify (PyPI package "graphifyy"), code-only mode.

.DESCRIPTION
  Installs the graphify CLI for code-only graphs and writes a privacy-safe env
  example to .\.pmkit\env\graphify.env.example in the current directory.
  Asks before every step. Never asks for or stores API keys.
  The two optional integration steps ("graphify install" and
  "graphify hook install") are NOT covered by -Yes. They always need a typed yes.
  Checked: 2026-10-17. Read catalog/graphify.md and the upstream README first.
  Run it from your project root. Windows PowerShell 5.1 compatible.

.PARAMETER DryRun
  Print every step and command. Change nothing.

.PARAMETER Yes
  Accept the core steps without asking (non-interactive).

.PARAMETER Version
  Install exactly this version (for example 0.9.92). Without it, the latest
  release is installed and the exact version is printed for you to record.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File graphify.ps1 -DryRun
#>
[CmdletBinding(PositionalBinding = $false)]
param(
  [switch]$DryRun,
  [switch]$Yes,
  [string]$Version = '',
  [switch]$Help,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
$Tool = 'graphify'

if ($Help) { Get-Help $MyInvocation.MyCommand.Path -Detailed; exit 0 }
if ($Rest) {
  [Console]::Error.WriteLine('Unknown option: ' + ($Rest -join ' '))
  [Console]::Error.WriteLine('Usage: ' + (Split-Path -Leaf $MyInvocation.MyCommand.Path) + ' [-DryRun] [-Yes] [-Version <v>] [-Help]')
  exit 2
}

# A version is digits first, then digits, letters, dots, + or -. A leading v is dropped.
$VersionGiven = $PSBoundParameters.ContainsKey('Version')
$Version = ($Version -replace '^v', '')
if ($VersionGiven -and ($Version -notmatch '^[0-9][0-9A-Za-z.+-]*$')) {
  [Console]::Error.WriteLine('Invalid version: "' + $Version + '". Use a release number such as 0.9.92.')
  exit 2
}

function Say([string]$Text) { Write-Host $Text }
function Hr { Write-Host ('-' * 60) }

function Resolve-Exe([string]$Name) {
  $c = Get-Command "$Name.cmd" -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($c) { return $c.Source }
  $c = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($c) { return $c.Source }
  return $null
}

function Read-YesNo([string]$Question) {
  $reply = ''
  try { $reply = Read-Host "$Question [y/N]" } catch { $reply = '' }
  return ($reply -match '^(y|yes)$')
}

function Ask([string]$Question) {
  if ($DryRun) { Say "[dry-run] Would ask: $Question [y/N] (showing the step as if yes)"; return $true }
  if ($Yes) { Say "$Question [y/N] y (-Yes)"; return $true }
  return (Read-YesNo $Question)
}

# Like Ask, but -Yes does not answer it.
# -Yes is checked first, so "-DryRun -Yes" previews what "-Yes" really does.
function Ask-Explicit([string]$Question) {
  if ($Yes) {
    if ($DryRun) { Say "[dry-run] Would skip: $Question (needs a typed yes, not covered by -Yes)" }
    else { Say '  Skipped: this step needs a typed yes and is not covered by -Yes.' }
    return $false
  }
  if ($DryRun) { Say "[dry-run] Would ask: $Question [y/N] (showing the step as if yes)"; return $true }
  return (Read-YesNo $Question)
}

# Run a native tool and judge success by its exit code only. With 'Stop',
# Windows PowerShell 5.1 turns any stderr line into a terminating error when
# output is redirected (agents, IDE tasks, CI, *> log.txt).
function Invoke-Native([string]$Exe, [string[]]$Arguments) {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $code = 0
  try { & $Exe @Arguments; $code = $LASTEXITCODE } finally { $ErrorActionPreference = $prev }
  if ($code -ne 0) { throw "Command failed with exit code $code" }
}

function Invoke-Step([string]$Name, [string[]]$Arguments) {
  Say ('  > ' + $Name + ' ' + ($Arguments -join ' '))
  if ($DryRun) { return }
  $exe = Resolve-Exe $Name
  if (-not $exe) { throw "Command not found: $Name" }
  Invoke-Native $exe $Arguments
}

$EnvDir = Join-Path (Get-Location).Path '.pmkit\env'
$EnvFile = Join-Path $EnvDir "$Tool.env.example"

function Write-EnvExample([string]$Content) {
  if ($DryRun) {
    Say "[dry-run] Would write $EnvFile with:"
    foreach ($line in ($Content -split "`r?`n")) { Say ('    ' + $line) }
    return
  }
  if (Test-Path -LiteralPath $EnvFile) { Say "  $EnvFile already exists. Not changed."; return }
  if (-not (Test-Path -LiteralPath $EnvDir)) { New-Item -ItemType Directory -Path $EnvDir | Out-Null }
  [System.IO.File]::WriteAllText($EnvFile, $Content, (New-Object System.Text.UTF8Encoding($false)))
  Say "  Wrote $EnvFile"
}

# Package spec: pinned with -Version, otherwise the latest release.
$Pkg = 'graphifyy'
if ($Version) { $Pkg = "graphifyy==$Version" }

$Installer = $null
if (Resolve-Exe 'uv') { $Installer = 'uv' } elseif (Resolve-Exe 'pipx') { $Installer = 'pipx' }

Hr
Say 'pmkit installer: graphify, code-only mode    (Checked: 2026-10-17)'
if ($DryRun) { Say 'DRY RUN: nothing will be installed or written.' }
Hr
Say 'What it is: a CLI that builds a graph of your codebase. Code is parsed'
Say 'locally with tree-sitter and needs no LLM. Output goes to graphify-out/'
Say '(graph.json, GRAPH_REPORT.md, graph.html). Docs, PDFs and images need an'
Say 'LLM pass; this script sets up code-only mode, which skips that.'
Say ''
Say 'Plan'
Say '  Step 1  Install the CLI (exact package name, double y):'
Say "            uv tool install $Pkg      (fallback: pipx install $Pkg)"
if ($Version) {
  Say "          Pinned to $Version (-Version)."
} else {
  Say '          No -Version given: installs the latest release. Pin with -Version <v>.'
}
Say "  Step 2  Write a privacy-safe env example: $EnvFile"
Say '            (GRAPHIFY_BACKEND=none = code-only, no LLM backend at all)'
Say '  Optional, separate prompts, not covered by -Yes:'
Say '  Step 3  graphify install        (registers the /graphify skill)'
Say '  Step 4  graphify hook install   (git hooks that rebuild the graph)'
Say ''
Say 'Files and settings it touches'
Say "  - Steps 1-2: the uv/pipx tool folder in your user profile, and $EnvFile."
Say '  - Steps 3 and 4 touch more. Each is explained before it asks.'
Say '  - Running graphify later writes graphify-out\ in the folder you scan.'
Say ''
Say 'Network calls'
Say '  - Install: downloads graphifyy and its dependencies from PyPI.'
Say '  - Code-only runs with GRAPHIFY_BACKEND=none: no LLM calls. No telemetry'
Say '    code was found upstream.'
Say '  - Without GRAPHIFY_BACKEND=none, community labelling can send code symbol'
Say "    names to an LLM, and falls back to 'claude -p' (your subscription) if"
Say '    the claude CLI is on PATH.'
Say ''
Say 'API keys: none for code-only mode.'
Say ''
Say 'Warnings'
Say "  - The PyPI name is 'graphifyy' (two y). Other graphify* packages are not"
Say '    affiliated. Type it exactly.'
Say '  - The /graphify skill ignores GRAPHIFY_BACKEND. In skill mode it uses'
Say '    Gemini if GEMINI_API_KEY or GOOGLE_API_KEY is set, otherwise your host'
Say "    agent's model. For strictly local use, run the headless CLI."
Say '  - Install prints an upsell for a paid cloud product. You do not need it.'
Hr

Say 'Checking prerequisites'
if ($Installer) {
  Say "  Found: $Installer"
} else {
  Say '  Missing: uv or pipx.'
  Say '  uv:   https://docs.astral.sh/uv/   pipx: https://pipx.pypa.io/'
  Say '  graphify needs Python 3.10 or later. This script does not install prerequisites.'
  if ($DryRun) {
    $Installer = 'uv'
    Say '[dry-run] A real run would stop here. Showing the uv commands.'
  } else {
    exit 1
  }
}
Hr

if ($Installer -eq 'uv') { $installCmd = "uv tool install $Pkg" } else { $installCmd = "pipx install $Pkg" }
if (Ask "Step 1: install graphify with '$installCmd'?") {
  if ($Installer -eq 'uv') {
    Invoke-Step 'uv' @('tool', 'install', $Pkg)
  } else {
    Invoke-Step 'pipx' @('install', $Pkg)
  }
  Say '  If graphifyy was already installed, check the output above: the old version'
  Say '  may have been kept. To change versions, uninstall first (installers\README.md).'
} else {
  Say '  Skipped step 1.'
}
Hr

$envContent = @'
# graphify privacy-safe settings (written by pmkit). Checked: 2026-10-17
# This is an example file. Copy the lines you want into your shell yourself.
# Never put API keys in this file.
# PowerShell form: $env:GRAPHIFY_BACKEND = 'none'

# Code-only mode: disables every LLM backend, including the 'claude -p'
# community-labelling fallback. Code is parsed locally with tree-sitter.
GRAPHIFY_BACKEND=none

# Query logging is opt-in in the current code (the README says otherwise).
# This forces it off either way.
GRAPHIFY_QUERY_LOG_DISABLE=1

# Also: remove GEMINI_API_KEY and GOOGLE_API_KEY from this shell if docs must
# not go to Google. The /graphify skill uses Gemini when either is set.

# --- Optional local-model route (headless CLI only, NOT the /graphify skill) ---
# Uses a local Ollama server for the docs/PDF/image pass. Note the /v1 suffix.
# GRAPHIFY_BACKEND=ollama
# OLLAMA_BASE_URL=http://localhost:11434/v1
# OLLAMA_MODEL=qwen2.5-coder:7b
# Make sure the URL is localhost. LAN hosts are allowed with only a warning.
'@
if (Ask "Step 2: write $EnvFile (privacy-safe settings, no keys)?") {
  Write-EnvExample $envContent
} else {
  Say '  Skipped step 2.'
}
Hr

Say 'Step 3 (optional): graphify install'
Say '  What it writes (as checked for the Claude Code platform):'
Say '  - Copies SKILL.md and a references\ folder to ~\.claude\skills\graphify\'
Say '    (or under $CLAUDE_CONFIG_DIR, or .claude\skills\ with --project).'
Say '  - APPENDS a registration block to ~\.claude\CLAUDE.md'
Say '    (or .claude\CLAUDE.md with --project).'
Say '  - Writes a lock file under ~\.cache\graphify\skill-locks\.'
Say '  On Windows, bare install uses the "windows" platform variant. Its exact'
Say '  paths are unverified. Check the command output to see what it wrote.'
Say "  It does not detect your agent. Other agents: 'graphify install --platform <name>'."
Say '  Reminder: the /graphify skill ignores GRAPHIFY_BACKEND (see warnings above).'
Say '  You can skip this. The CLI works without it: graphify extract <folder>'
$graphifyMissing = ((-not $DryRun) -and (-not (Resolve-Exe 'graphify')))
$pathHint = "  If step 1 ran, run 'uv tool update-shell' (or 'pipx ensurepath') and open a new shell."
if ($graphifyMissing) {
  Say '  graphify is not on PATH. Skipped step 3.'
  Say $pathHint
} elseif (Ask-Explicit "Run 'graphify install' now?") {
  Invoke-Step 'graphify' @('install')
} else {
  Say '  Skipped step 3.'
}
Hr

Say 'Step 4 (optional): graphify hook install'
Say '  What it writes in the current git repo:'
Say '  - Marker-delimited blocks in 4 git hooks: post-commit, post-checkout,'
Say '    post-merge, post-rewrite (respects core.hooksPath and Husky).'
Say '  - git config entries merge.graphify.* (a union merge driver for graph.json).'
Say '  - Edits .gitattributes, which is a tracked file.'
Say "  After 'git pull' you still run 'graphify update .' yourself."
$inGit = $false
$gitExe = Resolve-Exe 'git'
if ($gitExe) {
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $null = & $gitExe rev-parse --is-inside-work-tree 2>$null
  if ($LASTEXITCODE -eq 0) { $inGit = $true }
  $ErrorActionPreference = $prevEap
}
$here = (Get-Location).Path
if ((-not $inGit) -and (-not $DryRun)) {
  Say '  Not inside a git repository. Skipped step 4.'
} elseif ($graphifyMissing) {
  Say '  graphify is not on PATH. Skipped step 4.'
  Say $pathHint
} elseif (Ask-Explicit "Run 'graphify hook install' in ${here}?") {
  Invoke-Step 'graphify' @('hook', 'install')
} else {
  Say '  Skipped step 4.'
}
Hr

Say 'Installed version'
if ($DryRun) {
  Say "[dry-run] Would list the installed graphifyy version from $Installer."
  if ($Version) { Say "[dry-run] Would check that it is $Version." }
} else {
  $line = $null
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  if ($Installer -eq 'uv') {
    $line = & (Resolve-Exe 'uv') tool list 2>$null | Where-Object { $_ -match '^graphifyy' } | Select-Object -First 1
  } else {
    $line = & (Resolve-Exe 'pipx') list 2>$null | Where-Object { $_ -match 'graphifyy' } | Select-Object -First 1
  }
  $ErrorActionPreference = $prevEap
  if ($line) {
    $got = ''
    if (([string]$line) -match '([0-9]+(\.[0-9]+)+[0-9A-Za-z.+-]*)') { $got = $Matches[1] }
    $gotShow = $got
    if (-not $gotShow) { $gotShow = '<version>' }
    Say "  $line"
    Say '  Record this exact version in the "Installed tools" table of SETUP_DECISIONS.md.'
    Say "  To install the same version again:  graphify.ps1 -Version $gotShow"
    if ($Version -and ($got -ne $Version)) {
      Say "  WARNING: you asked for $Version, but $gotShow is installed."
    }
  } else {
    Say "  graphifyy not found in the $Installer tool list."
  }
}
Say ''
Say 'Next'
Say '  1. Try it on a small folder first, in code-only mode:'
Say "       `$env:GRAPHIFY_BACKEND = 'none'; graphify extract <folder>"
Say "     Check 'graphify --help' for current flags. Releases come every few days."
Say '  2. Record the tool, exact version, date and trigger in SETUP_DECISIONS.md.'
Say '  3. If LOG.md exists, log it:  python .pmkit\pmkit.py log --type TOOL-ADD --summary "Added graphify <version> (code-only): <trigger>"'
Say '  4. INFERRED edges are guesses. Do not mark them verified in knowledge\ without review.'
Hr
