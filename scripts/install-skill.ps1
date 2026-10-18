<#
.SYNOPSIS
Assemble and install the Claude Code skill "project-setup".

.DESCRIPTION
Writes:
  <dest>\project-setup\SKILL.md
  <dest>\project-setup\references\{interview,catalog,guides}\
  <dest>\project-setup\references\REPO_PATH.txt  (where this repo lives)
  <dest>\project-setup\template\

Default <dest> is ~\.claude\skills. -Project <dir> uses <dir>\.claude\skills.
Network calls: none. Works with Windows PowerShell 5.1 and PowerShell 7.

.EXAMPLE
.\scripts\install-skill.ps1

.EXAMPLE
.\scripts\install-skill.ps1 -Project C:\work\my-project -DryRun
#>
[CmdletBinding()]
param(
    [string]$Project,
    [switch]$DryRun,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot

$missing = $false
foreach ($p in @('skill\project-setup\SKILL.md', 'interview', 'catalog', 'guides', 'template')) {
    if (-not (Test-Path -LiteralPath (Join-Path $repo $p))) {
        Write-Host "Missing in repo: $p"
        $missing = $true
    }
}
if ($missing) {
    Write-Error 'Cannot assemble the skill. Run this from a complete copy of the repo.'
    exit 1
}

if ($Project) {
    if (-not (Test-Path -LiteralPath $Project -PathType Container)) {
        Write-Error "Project directory does not exist: $Project"
        exit 1
    }
    $projFull = (Resolve-Path -LiteralPath $Project).ProviderPath
    $dest = Join-Path (Join-Path $projFull '.claude') 'skills'
} else {
    $homeDir = $env:USERPROFILE
    if (-not $homeDir) { $homeDir = $HOME }
    $dest = Join-Path (Join-Path $homeDir '.claude') 'skills'
}
$skillDir = Join-Path $dest 'project-setup'

Write-Output 'This will install the project-setup skill.'
Write-Output "  From: $repo"
Write-Output "  To:   $skillDir"
Write-Output '  Copies: SKILL.md, interview\, catalog\, guides\ (into references\), template\'
Write-Output '  Network calls: none'
Write-Output ''

if (Test-Path -LiteralPath $skillDir) {
    Write-Output "An install already exists at: $skillDir"
    Write-Output 'Replacing it deletes that folder first, including any edits you made there.'
    if ($DryRun) {
        Write-Output 'Dry run: would ask before replacing it.'
    } elseif ($Yes) {
        Write-Output '-Yes given: replacing.'
    } else {
        try {
            $answer = Read-Host 'Replace the existing install? [y/N]'
        } catch {
            Write-Error 'No console to ask. Re-run with -Yes to replace, or remove the folder yourself.'
            exit 1
        }
        # Cast: Read-Host can return AutomationNull when stdin is closed, and a
        # -match on that is not a plain boolean.
        $answerText = "$answer"
        if (-not ($answerText.Trim() -match '^(y|yes)$')) {
            Write-Output 'Left the existing install unchanged.'
            exit 0
        }
    }
}

if ($DryRun) {
    Write-Output ''
    Write-Output 'Dry run. Would create:'
    Write-Output "  $skillDir\SKILL.md"
    Write-Output "  $skillDir\references\interview\"
    Write-Output "  $skillDir\references\catalog\"
    Write-Output "  $skillDir\references\guides\"
    Write-Output "  $skillDir\references\REPO_PATH.txt"
    Write-Output "  $skillDir\template\"
    exit 0
}

if (Test-Path -LiteralPath $skillDir) {
    Remove-Item -LiteralPath $skillDir -Recurse -Force -Confirm:$false
}
$refs = Join-Path $skillDir 'references'
New-Item -ItemType Directory -Path $refs -Force | Out-Null

Copy-Item -LiteralPath (Join-Path $repo 'skill\project-setup\SKILL.md') -Destination (Join-Path $skillDir 'SKILL.md')
foreach ($d in @('interview', 'catalog', 'guides')) {
    Copy-Item -LiteralPath (Join-Path $repo $d) -Destination (Join-Path $refs $d) -Recurse -Force
}
Copy-Item -LiteralPath (Join-Path $repo 'template') -Destination (Join-Path $skillDir 'template') -Recurse -Force

Get-ChildItem -LiteralPath $skillDir -Recurse -Directory -Force -Filter '__pycache__' |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force -Confirm:$false }
Get-ChildItem -LiteralPath $skillDir -Recurse -File -Force -Filter '*.pyc' |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -Confirm:$false }

[System.IO.File]::WriteAllText((Join-Path $refs 'REPO_PATH.txt'), $repo + "`n")

$count = (Get-ChildItem -LiteralPath $skillDir -Recurse -File -Force | Measure-Object).Count
Write-Output "Installed $count file(s) to $skillDir"
Write-Output ''
Write-Output 'Next: start Claude Code in your project and ask it to set up the project,'
Write-Output 'or type /project-setup.'
Write-Output ("The Level 2 installers stay in the repo: " + (Join-Path $repo 'levels\2-starter-tools\installers'))
