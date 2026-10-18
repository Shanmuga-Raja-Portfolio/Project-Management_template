<#
.SYNOPSIS
  pmkit: check which local model servers are running. Probes only. Installs nothing.

.DESCRIPTION
  Probes two local addresses and lists the models they report:
    Ollama     http://localhost:11434/api/tags
    LM Studio  http://localhost:1234/v1/models
  It installs nothing and writes nothing. Both requests stay on localhost.
  Checked: 2026-10-17. See guides/local-models.md.
  Windows PowerShell 5.1 compatible.

.PARAMETER DryRun
  Print what would be probed. Make no requests.

.PARAMETER Yes
  Accepted for consistency with the other installers. No effect.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File check-local-model.ps1
#>
[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$Yes,
  [switch]$Help,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

if ($Help) { Get-Help $MyInvocation.MyCommand.Path -Detailed; exit 0 }
if ($Rest) {
  [Console]::Error.WriteLine('Unknown option: ' + ($Rest -join ' '))
  [Console]::Error.WriteLine('Usage: ' + (Split-Path -Leaf $MyInvocation.MyCommand.Path) + ' [-DryRun] [-Yes] [-Help]')
  exit 2
}

function Say([string]$Text) { Write-Host $Text }
function Hr { Write-Host ('-' * 60) }

$OllamaUrl = 'http://localhost:11434/api/tags'
$LmStudioUrl = 'http://localhost:1234/v1/models'

# Keep the probes on localhost even if a system or env proxy is set.
try { [System.Net.WebRequest]::DefaultWebProxy = $null } catch { }

function Get-Json([string]$Url) {
  try {
    return (Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 3 -UseBasicParsing)
  } catch {
    return $null
  }
}

Hr
Say 'pmkit: local model check    (Checked: 2026-10-17)'
Say 'Probes (localhost only, 3 second timeout each):'
Say "  Ollama     GET $OllamaUrl"
Say "  LM Studio  GET $LmStudioUrl"
Say 'Files touched: none. Installs: none.'
Hr

if ($DryRun) {
  Say '[dry-run] Would run:'
  Say "  > Invoke-RestMethod -Uri $OllamaUrl -TimeoutSec 3"
  Say "  > Invoke-RestMethod -Uri $LmStudioUrl -TimeoutSec 3"
  Hr
  exit 0
}

$foundAny = $false

Say 'Ollama'
$o = Get-Json $OllamaUrl
# Count it as running only if the reply has the expected "models" list.
if (($null -ne $o) -and ($o.PSObject.Properties.Name -contains 'models')) {
  $foundAny = $true
  Say '  Running at http://localhost:11434'
  $names = @($o.models | Where-Object { $null -ne $_ } | ForEach-Object { $_.name })
  if ($names.Count -gt 0) {
    Say '  Models:'
    foreach ($n in $names) { Say "    - $n" }
  } else {
    Say '  No models listed. Pull one with: ollama pull <model>'
  }
} else {
  Say "  Not reachable. Start it with 'ollama serve' or the Ollama app, if installed."
}
Say ''

Say 'LM Studio'
$l = Get-Json $LmStudioUrl
# Count it as running only if the reply has the expected "data" list.
if (($null -ne $l) -and ($l.PSObject.Properties.Name -contains 'data')) {
  $foundAny = $true
  Say '  Running at http://localhost:1234/v1'
  $ids = @($l.data | Where-Object { $null -ne $_ } | ForEach-Object { $_.id })
  if ($ids.Count -gt 0) {
    Say '  Models:'
    foreach ($i in $ids) { Say "    - $i" }
  } else {
    Say '  No models listed. Load a model in LM Studio and start its local server.'
  }
} else {
  Say '  Not reachable. Start the local server in LM Studio, if installed.'
}
Hr

Say 'Base URLs differ per tool. The /v1 suffix is the most common mistake:'
Say '  LangExtract (Ollama)        http://localhost:11434        no /v1'
Say '  graphify headless (Ollama)  http://localhost:11434/v1'
Say '  Open Code Review (Ollama)   http://127.0.0.1:11434/v1'
Say '  Strix (Ollama)              http://localhost:11434'
Say '  LM Studio (any tool)        http://localhost:1234/v1'
Say ''
Say 'Honest limits'
Say '  - Tools that need tool calls or agent loops (Open Code Review, Strix) are'
Say "    unreliable below about 30B parameters. Strix's docs say under 70B 'struggle'."
Say '  - Local mode is the privacy option, not a free copy of a frontier model.'
Say '  - Run each tool''s smoke test (guides/local-models.md) before relying on it.'
if (-not $foundAny) {
  Say ''
  Say 'No local model server found. That is fine: Level 1 and 2 work without one.'
}
Hr
