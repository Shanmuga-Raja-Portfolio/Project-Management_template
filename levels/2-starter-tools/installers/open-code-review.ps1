<#
.SYNOPSIS
  pmkit Level 2 installer: Open Code Review ("ocr"), delegation mode.

.DESCRIPTION
  Installs the Open Code Review CLI from npm, prints the Claude Code plugin
  commands for delegation mode, and writes a privacy-safe env example to
  .\.pmkit\env\open-code-review.env.example in the current directory.
  Asks before every step. Never asks for or stores API keys.
  Checked: 2026-10-17. Read catalog/open-code-review.md and the upstream README first.
  Run it from your project root. Windows PowerShell 5.1 compatible.

.PARAMETER DryRun
  Print every step and command. Change nothing.

.PARAMETER Yes
  Accept every step without asking (non-interactive).

.PARAMETER Version
  Install exactly this version (for example 1.13.1). Without it, the latest
  release is installed and the exact version is printed for you to record.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File open-code-review.ps1 -DryRun
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
$Tool = 'open-code-review'

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
  [Console]::Error.WriteLine('Invalid version: "' + $Version + '". Use a release number such as 1.13.1.')
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

function Ask([string]$Question) {
  if ($DryRun) { Say "[dry-run] Would ask: $Question [y/N] (showing the step as if yes)"; return $true }
  if ($Yes) { Say "$Question [y/N] y (-Yes)"; return $true }
  $reply = ''
  try { $reply = Read-Host "$Question [y/N]" } catch { $reply = '' }
  return ($reply -match '^(y|yes)$')
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
$Pkg = '@alibaba-group/open-code-review'
if ($Version) { $Pkg = "@alibaba-group/open-code-review@$Version" }

Hr
Say 'pmkit installer: Open Code Review (ocr), delegation mode    (Checked: 2026-10-17)'
if ($DryRun) { Say 'DRY RUN: nothing will be installed or written.' }
Hr
Say "What it is: a Go CLI for LLM review of git diffs, or of files with 'ocr scan'."
Say 'File selection and rule matching are plain code. In delegation mode OCR makes'
Say 'no LLM call: it hands the files and rules to your agent, and your agent reviews.'
Say ''
Say 'Plan'
Say '  Step 1  Install the CLI globally:'
Say "            npm i -g $Pkg"
if ($Version) {
  Say "          Pinned to $Version (-Version)."
} else {
  Say '          No -Version given: installs the latest release. Pin with -Version <v>.'
}
Say '  Step 2  Show the Claude Code plugin commands for delegation mode.'
Say '          You run them yourself inside Claude Code. This script does not.'
Say "  Step 3  Write a privacy-safe env example: $EnvFile"
Say ''
Say 'Files and settings it touches'
Say "  - Your global npm folder (adds the 'ocr' command)."
Say "  - $EnvFile (new file; skipped if it exists)."
Say '  - It does NOT create ~\.opencodereview\config.json. You decide on that.'
Say ''
Say 'Network calls'
Say '  - Install: downloads the package from the npm registry.'
Say "  - Delegation mode: none on the OCR side. Your agent's normal model calls apply."
Say '  - Default (non-delegation) mode: diffs and file contents go to the LLM'
Say '    provider you configure. Many built-in presets are hosted in China.'
Say '    Choose a provider on purpose.'
Say '  - Telemetry is off by default (opt-in with OCR_ENABLE_TELEMETRY=1).'
Say ''
Say 'API keys: none for delegation mode.'
Say ''
Say "Warning: if OCR's own LLM is not configured, it looks in this order:"
Say '  ~\.opencodereview\config.json, then OCR_LLM_URL/OCR_LLM_TOKEN/OCR_LLM_MODEL,'
Say '  then it SILENTLY reuses ANTHROPIC_BASE_URL/ANTHROPIC_AUTH_TOKEN/ANTHROPIC_MODEL.'
Say '  So a non-delegation run can bill or route through your Claude Code settings.'
Hr

Say 'Checking prerequisites'
$prereqOk = $true
$npmExe = Resolve-Exe 'npm'
if ($npmExe) {
  $npmVer = (& $npmExe --version)
  Say "  npm: $npmVer"
} else {
  Say '  Missing: npm (comes with Node.js). Get it from https://nodejs.org/ or winget.'
  $prereqOk = $false
}
$gitExe = Resolve-Exe 'git'
if ($gitExe) {
  $gitLine = (& $gitExe --version)
  Say "  git: $gitLine"
  $gitOk = $false
  if ($gitLine -match '(\d+)\.(\d+)') {
    $gMaj = [int]$Matches[1]; $gMin = [int]$Matches[2]
    if (($gMaj -gt 2) -or (($gMaj -eq 2) -and ($gMin -ge 41))) { $gitOk = $true }
  }
  if (-not $gitOk) {
    Say '  OCR needs git 2.41 or later. Update git from https://git-scm.com/'
    $prereqOk = $false
  }
} else {
  Say '  Missing: git 2.41 or later. Get it from https://git-scm.com/'
  $prereqOk = $false
}
Say "  Other install routes upstream: a release binary checked against sha256sum.txt,"
Say "  or 'brew install open-code-review' on macOS/Linux."
if (-not $prereqOk) {
  if ($DryRun) { Say '[dry-run] A real run would stop here.' } else { Say '  This script does not install prerequisites.'; exit 1 }
}
Hr

if (Ask "Step 1: install ocr with 'npm i -g $Pkg'?") {
  Invoke-Step 'npm' @('i', '-g', $Pkg)
} else {
  Say '  Skipped step 1.'
}
Hr

if (Ask 'Step 2: show the Claude Code plugin commands for delegation mode?') {
  Say '  Run these inside Claude Code (type them at the Claude Code prompt):'
  Say ''
  Say '    /plugin marketplace add alibaba/open-code-review'
  Say '    /plugin install open-code-review@open-code-review'
  Say ''
  Say '  This adds two commands:'
  Say '    /open-code-review:delegate-review   delegation mode: your agent reviews, no OCR key'
  Say "    /open-code-review:review            uses OCR's own LLM (see the warning above)"
  Say '  Use delegate-review unless you have set up OCR''s own provider on purpose.'
  Say ''
  Say '  Other agents: the delegate skill installs with'
  Say '    npx skills add alibaba/open-code-review --skill open-code-review-delegate'
  Say "    (npx fetches the latest 'skills' CLI from npm, not pinned, and may prompt.)"
  Say '  Plain CLI delegation (no plugin):'
  Say '    ocr delegate preview --format json'
  Say '    ocr delegate rule --format json <files>'
} else {
  Say '  Skipped step 2.'
}
Hr

$envContent = @'
# Open Code Review privacy-safe settings (written by pmkit). Checked: 2026-10-17
# This is an example file. Copy the lines you want into your shell yourself.
# Never put real API keys in this file.
# PowerShell form: $env:OCR_LLM_PROTOCOL = 'openai'

# Recommended: delegation mode (/open-code-review:delegate-review or
# 'ocr delegate ...'). OCR makes no LLM call, so nothing below is needed.

# Telemetry and content logging are off by default. Leave these unset:
#   OCR_ENABLE_TELEMETRY
#   OCR_CONTENT_LOGGING

# If you run OCR's own LLM, configure it explicitly so it does not fall back
# to ANTHROPIC_BASE_URL / ANTHROPIC_AUTH_TOKEN / ANTHROPIC_MODEL.

# --- Optional local-model route (Ollama, OpenAI protocol, note the /v1) ---
# The model must emit native tool calls (qwen3 works; deepseek-r1 fails with
# "No tool calls parsed"). Expect to need a large model (about 30B+).
# OCR_LLM_URL=http://127.0.0.1:11434/v1
# OCR_LLM_TOKEN=ollama            # placeholder; must be non-empty
# OCR_LLM_MODEL=qwen3:32b
# OCR_LLM_PROTOCOL=openai
# OCR_LLM_TIMEOUT=600             # default 300 s; raise for slow local models
# LM Studio (http://localhost:1234/v1) is undocumented upstream: untested.
'@
if (Ask "Step 3: write $EnvFile (privacy-safe settings, no keys)?") {
  Write-EnvExample $envContent
} else {
  Say '  Skipped step 3.'
}
Hr

Say 'Installed version'
if ($DryRun) {
  Say '[dry-run] Would run: npm ls -g @alibaba-group/open-code-review --depth=0'
  if ($Version) { Say "[dry-run] Would check that it is $Version." }
} elseif ($npmExe) {
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $line = & $npmExe ls -g '@alibaba-group/open-code-review' --depth=0 2>$null | Where-Object { $_ -match 'open-code-review' } | Select-Object -First 1
  $ErrorActionPreference = $prevEap
  if ($line) {
    $got = ''
    if (([string]$line) -match 'open-code-review@(\S+)') { $got = $Matches[1] }
    $gotShow = $got
    if (-not $gotShow) { $gotShow = '<version>' }
    Say "  $line"
    Say '  Record this exact version in the "Installed tools" table of SETUP_DECISIONS.md.'
    Say "  To install the same version again:  open-code-review.ps1 -Version $gotShow"
    if ($Version -and ($got -ne $Version)) {
      Say "  WARNING: you asked for $Version, but $gotShow is installed."
    }
  } else {
    Say '  Package not found in the global npm folder.'
  }
}
Say ''
Say 'Next'
Say '  1. Smoke test on a 1-line change: make a small edit, then run the delegate'
Say '     review in your agent.'
Say '  2. Record the tool, exact version, date and trigger in SETUP_DECISIONS.md.'
Say '  3. If LOG.md exists, log it:  python .pmkit\pmkit.py log --type TOOL-ADD --summary "Added Open Code Review <version> (delegation): <trigger>"'
Hr
