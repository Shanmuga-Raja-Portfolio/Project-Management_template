<#
.SYNOPSIS
  pmkit Level 2 installer: LangExtract (Python library for grounded extraction).

.DESCRIPTION
  Installs the LangExtract Python library, by default into a project venv at
  .\.pmkit\venv-langextract, and writes a privacy-safe env example to
  .\.pmkit\env\langextract.env.example in the current directory.
  Asks before every step. Never asks for or stores API keys.
  Checked: 2026-10-17. Read catalog/langextract.md and the upstream README first.
  Run it from your project root. Windows PowerShell 5.1 compatible.

.PARAMETER DryRun
  Print every step and command. Change nothing.

.PARAMETER Yes
  Accept every step without asking (uses the venv).

.PARAMETER Version
  Install exactly this version (for example 1.7.1). Without it, the latest
  release is installed and the exact version is printed for you to record.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File langextract.ps1 -DryRun
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
$Tool = 'langextract'

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
  [Console]::Error.WriteLine('Invalid version: "' + $Version + '". Use a release number such as 1.7.1.')
  exit 2
}

function Say([string]$Text) { Write-Host $Text }
function Hr { Write-Host ('-' * 60) }

function Resolve-Exe([string]$Name) {
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

# Used for the "install into your current Python" fallback. -Yes means "use the venv".
function Ask-Explicit([string]$Question) {
  if ($DryRun) { Say "[dry-run] Would ask: $Question [y/N]"; return $false }
  if ($Yes) { return $false }
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

function Invoke-Exe([string]$Exe, [string[]]$Arguments) {
  Say ('  > ' + $Exe + ' ' + ($Arguments -join ' '))
  if ($DryRun) { return }
  Invoke-Native $Exe $Arguments
}

$EnvDir = Join-Path (Get-Location).Path '.pmkit\env'
$EnvFile = Join-Path $EnvDir "$Tool.env.example"
$VenvDir = Join-Path (Get-Location).Path '.pmkit\venv-langextract'

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

# Find a real Python 3.10+. Skips store stubs that fail to run.
$Py = $null
$PyPre = @()
$check = 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)'
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
foreach ($cand in @(@{ n = 'python'; a = @() }, @{ n = 'python3'; a = @() }, @{ n = 'py'; a = @('-3') })) {
  $exe = Resolve-Exe $cand.n
  if (-not $exe) { continue }
  try {
    $argsList = @($cand.a) + @('-c', $check)
    & $exe @argsList 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $Py = $exe; $PyPre = @($cand.a); break }
  } catch { }
}
$ErrorActionPreference = $prevEap
$pyShow = 'python'
if ($Py) { $pyShow = (($Py + ' ' + ($PyPre -join ' ')).Trim()) }

# Package spec: pinned with -Version, otherwise the latest release.
$Pkg = 'langextract'
$PkgOpenAI = 'langextract[openai]'
if ($Version) { $Pkg = "langextract==$Version"; $PkgOpenAI = "langextract[openai]==$Version" }

Hr
Say 'pmkit installer: LangExtract    (Checked: 2026-10-17)'
if ($DryRun) { Say 'DRY RUN: nothing will be installed or written.' }
Hr
Say 'What it is: a Python library. lx.extract() pulls entities out of text using'
Say 'a prompt and a few examples, and records the character span each one came'
Say 'from, so a person can check it. Items it cannot align get no span.'
Say 'It is a library you call from a script, not a CLI or a service.'
Say ''
Say 'Plan'
Say "  Step 1  Create a project venv:  $pyShow -m venv $VenvDir"
Say '          (if you say no, you can install into your current Python instead)'
Say "  Step 2  Install:  python -m pip install $Pkg   (inside the venv)"
if ($Version) {
  Say "          Pinned to $Version (-Version)."
} else {
  Say '          No -Version given: installs the latest release. Pin with -Version <v>.'
}
Say "  Step 3  Write a privacy-safe env example: $EnvFile"
Say ''
Say 'Files and settings it touches'
Say "  - $VenvDir (new folder). Keep it out of git: the kit .gitignore already lists .pmkit/venv-*/; add that line if you use your own .gitignore."
Say "  - $EnvFile (new file; skipped if it exists)."
Say ''
Say 'Network calls'
Say '  - Install: downloads from PyPI. The core install also pulls google-genai'
Say '    and google-cloud-storage, even if you only use Ollama.'
Say '  - Runtime: your text goes to whichever model you call. Gemini or OpenAI:'
Say '    it leaves the machine. Local Ollama: it stays local.'
Say ''
Say 'API keys: none for local Ollama. Cloud models read GEMINI_API_KEY (then'
Say 'LANGEXTRACT_API_KEY) or OPENAI_API_KEY (then LANGEXTRACT_API_KEY).'
Say 'Set those yourself if you need them. This script never asks for them.'
Say ''
Say 'Notes'
Say '  - Ollama has JSON mode only, no strict output schema. Leave fence_output'
Say '    and use_schema_constraints unset.'
Say '  - Cost grows with document length x extraction_passes.'
Say '  - Health-related use is also under the Health AI Developer Foundations terms.'
Hr

Say 'Checking prerequisites'
if ($Py) {
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $verArgs = @($PyPre) + @('--version')
  $pyVer = (& $Py @verArgs 2>&1) | Out-String
  $ErrorActionPreference = $prevEap
  Say ('  python: ' + $pyVer.Trim() + '  (' + $pyShow + ')')
} else {
  Say '  Missing: Python 3.10 or later. Get it from https://www.python.org/downloads/ or winget.'
  Say '  This script does not install it.'
  if ($DryRun) { Say '[dry-run] A real run would stop here.'; $Py = 'python' } else { exit 1 }
}
Hr

# Step 1: venv (or fallback)
$TargetPy = $null
$useVenv = $false
$winPy = Join-Path $VenvDir 'Scripts\python.exe'
$posixPy = Join-Path $VenvDir 'bin/python'

function Get-VenvPython {
  if (Test-Path -LiteralPath $winPy) { return $winPy }
  if (Test-Path -LiteralPath $posixPy) { return $posixPy }
  return $null
}

function New-Venv {
  try {
    Invoke-Exe $Py (@($PyPre) + @('-m', 'venv', $VenvDir))
  } catch {
    if (Test-Path -LiteralPath $VenvDir) { Remove-Item -LiteralPath $VenvDir -Recurse -Force -ErrorAction SilentlyContinue }
    Say "  Creating the venv failed ($($_.Exception.Message)). Removed the partial $VenvDir."
    exit 1
  }
}

function Test-VenvPip([string]$VPy) {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $ok = $false
  try { & $VPy -m pip --version 2>$null | Out-Null; $ok = ($LASTEXITCODE -eq 0) } catch { $ok = $false } finally { $ErrorActionPreference = $prev }
  return $ok
}

if ((Test-Path -LiteralPath $VenvDir) -and (-not $DryRun)) {
  $vpy = Get-VenvPython
  if ($vpy -and (Test-VenvPip $vpy)) {
    Say "Step 1: $VenvDir already exists and has pip. Reusing it."
    $useVenv = $true
  } else {
    Say "Step 1: $VenvDir exists but is broken (no python or no pip inside)."
    if (Ask '  Delete it and create a new venv?') {
      Remove-Item -LiteralPath $VenvDir -Recurse -Force
      New-Venv
      $useVenv = $true
    }
  }
} elseif (Ask "Step 1: create a venv at ${VenvDir}?") {
  New-Venv
  $useVenv = $true
}
if ($useVenv) {
  $vpy = Get-VenvPython
  if ($vpy) { $TargetPy = $vpy }
  elseif ($DryRun) { $TargetPy = $winPy }
  else { Say "  Could not find python inside $VenvDir."; exit 1 }
} else {
  Say '  No venv.'
  if (Ask-Explicit "Install into your current Python instead ($pyShow)?") {
    $TargetPy = $Py
  } else {
    Say "  Skipped steps 1-2. To install by hand later:  python -m pip install `"$Pkg`""
  }
}
Hr

# Step 2: install
if ($TargetPy) {
  if (Ask "Step 2: install langextract with '$TargetPy -m pip install $Pkg'?") {
    if ($TargetPy -eq $Py) { $pipArgs = @($PyPre) + @('-m', 'pip', 'install', $Pkg) } else { $pipArgs = @('-m', 'pip', 'install', $Pkg) }
    Invoke-Exe $TargetPy $pipArgs
    Say "  For OpenAI support later: $TargetPy -m pip install `"$PkgOpenAI`""
  } else {
    Say '  Skipped step 2.'
  }
  Hr
}

$envContent = @'
# LangExtract privacy-safe settings (written by pmkit). Checked: 2026-10-17
# This is an example file. Copy the lines you want into your shell yourself.
# Never put real API keys in this file.
# PowerShell form: $env:OLLAMA_BASE_URL = 'http://localhost:11434'

# --- Local route: Ollama native API. NO /v1 suffix here. ---
# LangExtract reads OLLAMA_BASE_URL in code (not in the README).
# You can pass model_url="http://localhost:11434" in code instead.
OLLAMA_BASE_URL=http://localhost:11434
# Use model_id="gemma2:2b" or larger. Recall drops with small models.
# JSON mode only on Ollama: leave fence_output / use_schema_constraints unset.

# --- LM Studio / other OpenAI-compatible server (untested upstream) ---
# In code: lx.factory.ModelConfig(model_id="<name>", provider="openai",
#   provider_kwargs={"base_url": "http://localhost:1234/v1", "api_key": "lm-studio"})
# Pass api_key explicitly: env lookup only matches gpt* model ids.

# --- Cloud keys: set them in your shell yourself if you choose a cloud model ---
# GEMINI_API_KEY / LANGEXTRACT_API_KEY / OPENAI_API_KEY
# With a cloud model, your documents leave this machine.
'@
if (Ask "Step 3: write $EnvFile (privacy-safe settings, no keys)?") {
  Write-EnvExample $envContent
} else {
  Say '  Skipped step 3.'
}
Hr

Say 'Installed version'
if ($DryRun) {
  Say '[dry-run] Would read the langextract version from the chosen Python.'
  if ($Version) { Say "[dry-run] Would check that it is $Version." }
} elseif ($TargetPy) {
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $vArgs = @()
  if ($TargetPy -eq $Py) { $vArgs = @($PyPre) }
  $vArgs = $vArgs + @('-c', 'import importlib.metadata as m; print(m.version(''langextract''))')
  $ver = (& $TargetPy @vArgs 2>$null)
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prevEap
  if ($code -eq 0 -and $ver) {
    $ver = ([string]$ver).Trim()
    Say "  langextract $ver"
    Say '  Record this exact version in the "Installed tools" table of SETUP_DECISIONS.md.'
    Say "  To install the same version again:  langextract.ps1 -Version $ver"
    if ($Version -and ($ver -ne $Version)) {
      Say "  WARNING: you asked for $Version, but $ver is installed."
    }
  } else {
    Say "  langextract is not installed in $TargetPy."
  }
} else {
  Say '  Not installed by this run.'
}
Say ''
Say 'Next'
Say '  1. Run the one-sentence smoke test in guides/local-models.md before'
Say '     relying on the local route.'
Say '  2. Record the tool, exact version, date and trigger in SETUP_DECISIONS.md.'
Say '  3. If LOG.md exists, log it:  python .pmkit\pmkit.py log --type TOOL-ADD --summary "Added LangExtract <version>: <trigger>"'
Hr
