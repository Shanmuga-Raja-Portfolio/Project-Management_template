<#
.SYNOPSIS
  pmkit Level 2 installer: Archify (agent skill that renders validated diagrams).

.DESCRIPTION
  Installs the Archify agent skill and writes a privacy-safe env example to
  .\.pmkit\env\archify.env.example in the current directory.
  Asks before every step. Never asks for or stores API keys.
  Checked: 2026-10-17. Read catalog/archify.md and the upstream README first.
  Run it from your project root. Windows PowerShell 5.1 compatible.

.PARAMETER DryRun
  Print every step and command. Change nothing.

.PARAMETER Yes
  Accept every step without asking (non-interactive).

.PARAMETER Version
  Check that the installed Archify is exactly this version (for example 3.1.0).
  The install route cannot pick a release, so a mismatch is reported and
  the script exits with code 3.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File archify.ps1 -DryRun
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
$Tool = 'archify'

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
  [Console]::Error.WriteLine('Invalid version: "' + $Version + '". Use a release number such as 3.1.0.')
  exit 2
}

function Say([string]$Text) { Write-Host $Text }
function Hr { Write-Host ('-' * 60) }

# Prefer the .cmd shim on Windows so execution policy does not block a .ps1 shim.
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

Hr
Say 'pmkit installer: Archify    (Checked: 2026-10-17)'
if ($DryRun) { Say 'DRY RUN: nothing will be installed or written.' }
Hr
Say 'What it is: an agent skill. Your agent writes typed JSON for one diagram'
Say "type. Archify's Node validators check it and 'deliver' writes one"
Say 'self-contained HTML file. Archify makes no LLM calls itself.'
Say ''
Say 'Plan'
Say '  Step 1  Install the skill globally:'
Say '            npx skills add tt-a1i/archify -g'
Say "          npx fetches the latest 'skills' CLI from npm (not pinned)."
Say '          The skills CLI installs the current Archify release. It has no'
Say '          documented way to pick an older one, so this script cannot pin it.'
if ($Version) {
  Say "          -Version ${Version}: after install, the script checks the installed"
  Say "          version and exits with code 3 if it is not $Version."
}
Say '          npx may ask "Ok to proceed?" and the skills CLI may ask which'
Say '          agents to install for. -Yes does not answer those prompts.'
Say '  Step 2  Write a privacy-safe env example:'
Say "            $EnvFile"
Say ''
Say 'Files and settings it touches'
Say "  - Your agent's global skills folder (for Claude Code: ~/.claude/skills/)."
Say '    The skills CLI picks the exact folder.'
Say "  - $EnvFile (new file; skipped if it exists)."
Say '  - Nothing else. No profile, no registry, no git config.'
Say ''
Say 'Network calls'
Say "  - Install: npx downloads the 'skills' CLI from the npm registry and"
Say '    fetches the skill from github.com/tt-a1i/archify.'
Say '  - Runtime: one optional update-check GET to'
Say '    https://tt-a1i.github.io/archify/skill-updates/archify/stable.json'
Say '    It sends no project data. The server still sees your IP and the time.'
Say '    ARCHIFY_UPDATE_CHECK_DISABLED=1 turns it off.'
Say '  - Delivered HTML can contain external links. They load only when clicked.'
Say ''
Say 'API keys: none. Archify uses whatever model your agent uses.'
Say ''
Say 'Before you install'
Say '  - Read archify/SKILL.md upstream. A skill gives instructions to your agent.'
Say '  - The upstream README has a sponsors section that promotes discounted API'
Say '    reseller services. Archify does not need them. Do not route keys through them.'
Say "  - Small or local models may fail Archify's JSON validation (undocumented)."
Hr

Say 'Checking prerequisites'
$prereqOk = $true
$nodeExe = Resolve-Exe 'node'
$npxExe = Resolve-Exe 'npx'
if ($nodeExe -and $npxExe) {
  $nodeVer = (& $nodeExe --version)
  Say "  node: $nodeVer"
  $major = 0
  if ($nodeVer -match '^v(\d+)\.') { $major = [int]$Matches[1] }
  if ($major -lt 18) {
    Say '  Node.js 18 or later is required. Update Node.js from https://nodejs.org/'
    $prereqOk = $false
  }
} else {
  Say '  Missing: Node.js with npx (version 18 or later).'
  Say '  Get it from https://nodejs.org/ or winget. This script does not install it.'
  $prereqOk = $false
}
if (-not $prereqOk) {
  if ($DryRun) { Say '[dry-run] A real run would stop here.' } else { exit 1 }
}
Hr

$installedNow = $false
if (Ask "Step 1: install the Archify skill with 'npx skills add tt-a1i/archify -g'?") {
  Invoke-Step 'npx' @('skills', 'add', 'tt-a1i/archify', '-g')
  $installedNow = $true
} else {
  Say '  Skipped step 1.'
}
Hr

$envContent = @'
# Archify privacy-safe settings (written by pmkit). Checked: 2026-10-17
# This is an example file. Copy the lines you want into your shell or agent
# environment yourself. Never put API keys in this file.
# PowerShell: $env:ARCHIFY_UPDATE_CHECK_DISABLED = '1'

# Turns off the only outbound request Archify makes (the update-check GET)
# and the reminder-state writes.
ARCHIFY_UPDATE_CHECK_DISABLED=1
'@
if (Ask "Step 2: write $EnvFile (privacy-safe settings, no keys)?") {
  Write-EnvExample $envContent
} else {
  Say '  Skipped step 2.'
}
Hr

Say 'Installed version'
$pinFailed = $false
if ($DryRun) {
  Say '[dry-run] Would read the version from archify\package.json in your skills folder.'
  if ($Version) { Say "[dry-run] Would check that it is $Version." }
} else {
  $found = $null
  $candidates = @(
    (Join-Path $HOME '.claude\skills\archify'),
    (Join-Path $HOME '.agents\skills\archify'),
    (Join-Path $HOME '.config\opencode\skills\archify'),
    (Join-Path (Get-Location).Path '.claude\skills\archify')
  )
  foreach ($d in $candidates) {
    if (Test-Path -LiteralPath (Join-Path $d 'package.json')) { $found = $d; break }
  }
  if ($found) {
    $ver = 'unknown'
    try { $ver = (Get-Content -Raw -LiteralPath (Join-Path $found 'package.json') | ConvertFrom-Json).version } catch { $ver = 'unknown' }
    Say "  Archify $ver  ($found)"
    Say '  Record this exact version in the "Installed tools" table of SETUP_DECISIONS.md.'
    $cli = Join-Path $found 'bin\archify.mjs'
    if (Test-Path -LiteralPath $cli) { Say "  Self-check you can run:  node `"$cli`" doctor" }
    if ($Version -and ([string]$ver -ne $Version)) {
      Say "  WARNING: you asked for $Version, but $ver is installed."
      Say '  For an exact release, use the clone route from the upstream README with'
      Say "  that release's tag (GitHub Releases list tags such as v3.1.0), or remove"
      Say '  this install (see installers\README.md, Removing a tool).'
      $pinFailed = $true
    }
  } else {
    Say '  Could not find archify\package.json in the usual skills folders.'
    Say "  Look in your agent's skills folder and read the 'version' field."
    if ($Version -and $installedNow) {
      Say "  WARNING: could not check that the installed version is $Version."
      $pinFailed = $true
    }
  }
}
Say ''
Say 'Next'
Say '  1. Record the tool, exact version, date and trigger in SETUP_DECISIONS.md.'
Say '  2. If LOG.md exists, log it:  python .pmkit\pmkit.py log --type TOOL-ADD --summary "Added Archify <version>: <trigger>"'
Say '  3. Set a revisit date. Remove it if nobody reads the diagrams.'
Hr
if ($pinFailed) { exit 3 }
