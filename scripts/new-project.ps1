<#
.SYNOPSIS
Copy the pmkit starter folder (template/) into a project directory.

.DESCRIPTION
Creates the target directory if needed. Never overwrites an existing file:
existing files are skipped and listed. For an existing .gitignore it prints
the lines you may want to add.

-Minimal copies only RULES.md, AGENTS.md, PROJECT.md, STATUS.md,
SETUP_DECISIONS.md, .gitignore and .pmkit\. -Only copies only the files or folders you list (comma-separated,
relative to template\). Without either, the whole starter folder is copied.

If .pmkit\ was copied, it then runs "python .pmkit\pmkit.py prune --dry-run"
in the target and shows which instruction lines point to files you did not
copy. It removes them after a yes (or with -Yes). With no console to ask and
no -Yes, it prunes nothing and prints the command. It runs "pmkit.py sync"
only if a line in .pmkit\adapters.txt is enabled (none is by default). It tries python3, python, then py -3; if none works, it
prints the commands to run. Works with Windows PowerShell 5.1 and PowerShell 7.

.EXAMPLE
.\scripts\new-project.ps1 -Target C:\work\my-project

.EXAMPLE
.\scripts\new-project.ps1 -Minimal C:\work\my-project

.EXAMPLE
.\scripts\new-project.ps1 -Minimal -Yes C:\work\my-project

.EXAMPLE
.\scripts\new-project.ps1 -Only PROJECT.md,STATUS.md,RULES.md,SETUP_DECISIONS.md C:\work\my-project -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Target,
    [switch]$Minimal,
    [string[]]$Only,
    [switch]$DryRun,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

# Usage errors: a plain message on stderr and exit code 2 (as in the .sh).
function Stop-Usage([string]$msg) {
    [Console]::Error.WriteLine($msg)
    exit 2
}

$repoUrl = 'https://github.com/Shanmuga-Raja-Portfolio/Project-Management_template'
$minimalSet = @('RULES.md', 'AGENTS.md', 'PROJECT.md', 'STATUS.md', 'SETUP_DECISIONS.md', '.gitignore', '.pmkit')

$repo = Split-Path -Parent $PSScriptRoot
$src = Join-Path $repo 'template'

if (-not (Test-Path -LiteralPath $src -PathType Container)) {
    Write-Error "Cannot find the template folder at: $src"
    exit 1
}

if ($Minimal -and $Only) {
    Stop-Usage 'Use -Minimal or -Only, not both.'
}

# Selection: normalised entries relative to template/ (forward slashes, no
# leading ./, no trailing /). Empty list means "everything".
$select = New-Object System.Collections.Generic.List[string]
$mode = 'full'
if ($Minimal) {
    $mode = 'minimal'
    foreach ($e in $minimalSet) { $select.Add($e) }
} elseif ($Only) {
    $mode = 'only'
    # -Only a,b,c arrives as an array from PowerShell and as one string from
    # "powershell -File"; split on commas either way.
    foreach ($chunk in $Only) {
        foreach ($raw in ($chunk -split ',')) {
            $e = ($raw.Trim() -replace '\\', '/') -replace '^\./', ''
            $e = $e.TrimEnd('/')
            if ($e.StartsWith('template/')) { $e = $e.Substring(9) }
            if (-not $e) { continue }
            if ($e.StartsWith('/') -or $e -match '(^|/)\.\.(/|$)' -or $e -match '^[A-Za-z]:') {
                Stop-Usage "-Only: not a path inside template/: $e"
            }
            if (-not (Test-Path -LiteralPath (Join-Path $src $e))) {
                $avail = (Get-ChildItem -LiteralPath $src -Force | ForEach-Object { $_.Name }) -join ' '
                Stop-Usage "-Only: not in template/: $e. Available: $avail"
            }
            $select.Add($e)
        }
    }
    if ($select.Count -eq 0) {
        Stop-Usage '-Only: the list is empty.'
    }
}

function Test-Selected([string]$rel) {
    if ($mode -eq 'full') { return $true }
    foreach ($e in $select) {
        if ($rel -ieq $e) { return $true }
        if ($rel.StartsWith($e + '/', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

if ((Test-Path -LiteralPath $Target) -and -not (Test-Path -LiteralPath $Target -PathType Container)) {
    Write-Error "Target exists and is not a directory: $Target"
    exit 1
}

$srcFull = (Resolve-Path -LiteralPath $src).ProviderPath.TrimEnd('\', '/')
# Resolve against the PowerShell location (not the process directory) and
# without creating anything, so a dry run and a real run agree.
$targetFull = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Target).TrimEnd('\', '/')

# Refuse a target inside template/ before creating anything.
if (($targetFull + '\').StartsWith($srcFull + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Error 'Target is inside the template folder. Pick another directory.'
    exit 1
}

if (-not $DryRun) {
    if (-not (Test-Path -LiteralPath $targetFull)) {
        New-Item -ItemType Directory -Path $targetFull -Force | Out-Null
    }
}

# Split a .gitignore pattern: Pat (no "!", no leading "/" or "**/", no
# trailing "/"), Neg ("!x"), Dir (trailing "/", folders only) and Anchor (a
# "/" before the end, so it matches from the root; otherwise it matches a
# name at any depth).
function Split-GitignorePattern([string]$p) {
    $r = @{ Neg = $false; Dir = $false; Anchor = $false; Pat = '' }
    if ($p.StartsWith('!')) { $r.Neg = $true; $p = $p.Substring(1) }
    if ($p.EndsWith('/')) { $r.Dir = $true; $p = $p.TrimEnd('/') }
    if ($p.StartsWith('**/')) { $p = $p.Substring(3) }
    elseif ($p.Contains('/')) { $r.Anchor = $true; $p = $p.TrimStart('/') }
    if ($p.Contains('/')) { $r.Anchor = $true }
    $r.Pat = $p
    return $r
}

# True if a line in $haveLines already covers the suggested line by meaning,
# not only by spelling: ".env*" covers ".env", "*.env" covers
# ".pmkit/env/*.env", ".pmkit/" covers ".pmkit/venv-*/". A negation is covered
# only by a negation; a root-only or folder-only line does not cover a wider
# one.
function Test-GitignoreCovers([string[]]$haveLines, [string]$want) {
    $w = Split-GitignorePattern $want
    $parts = @($w.Pat -split '/')
    foreach ($raw in $haveLines) {
        $h = $raw.Trim()
        if (-not $h -or $h.StartsWith('#')) { continue }
        $hp = Split-GitignorePattern $h
        if ($hp.Neg -ne $w.Neg) { continue }
        # Ignoring a parent folder covers everything in it: test the whole
        # path and each parent.
        for ($i = 0; $i -lt $parts.Count; $i++) {
            $last = ($i -eq $parts.Count - 1)
            if ($last -and $hp.Dir -and -not $w.Dir) { continue }
            if ($hp.Anchor) {
                if (-not $w.Anchor) { continue }
                $prefix = ($parts[0..$i] -join '/')
                if ($prefix -eq $hp.Pat -or $prefix -like $hp.Pat) { return $true }
            } else {
                if ($parts[$i] -eq $hp.Pat -or $parts[$i] -like $hp.Pat) { return $true }
            }
        }
    }
    return $false
}

$created = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]
$gitignoreAdd = New-Object System.Collections.Generic.List[string]

$files = Get-ChildItem -LiteralPath $srcFull -Recurse -File -Force | Sort-Object FullName
foreach ($f in $files) {
    $rel = $f.FullName.Substring($srcFull.Length).TrimStart('\', '/')
    if ($rel -like '*__pycache__*' -or $rel -like '*.pyc') { continue }
    $relShown = $rel -replace '\\', '/'
    if (-not (Test-Selected $relShown)) { continue }
    $dest = Join-Path $targetFull $rel
    if (Test-Path -LiteralPath $dest) {
        $skipped.Add($relShown)
        if ($relShown -eq '.gitignore' -and (Test-Path -LiteralPath $dest -PathType Leaf)) {
            $have = @(Get-Content -LiteralPath $dest | ForEach-Object { $_.TrimEnd("`r") })
            foreach ($line in (Get-Content -LiteralPath $f.FullName)) {
                $l = $line.TrimEnd("`r")
                if (-not $l -or $l.StartsWith('#')) { continue }
                if (($l.StartsWith('.pmkit/') -or $l.StartsWith('!.pmkit/')) -and -not (Test-Selected '.pmkit/pmkit.py')) { continue }
                if (-not (Test-GitignoreCovers $have $l)) { $gitignoreAdd.Add($l) }
            }
        }
        continue
    }
    if (-not $DryRun) {
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $f.FullName -Destination $dest
    }
    $created.Add($relShown)
}

if ($DryRun) {
    Write-Output 'Dry run. Nothing was changed.'
    $verb = 'Would create'
} else {
    $verb = 'Created'
}

Write-Output "Target: $targetFull"
if ($mode -eq 'minimal') { Write-Output ('Selection: -Minimal (' + ($minimalSet -join ',') + ')') }
if ($mode -eq 'only') { Write-Output ('Selection: -Only ' + ($select -join ',')) }
Write-Output ''
Write-Output ("{0} {1} file(s):" -f $verb, $created.Count)
foreach ($c in $created) { Write-Output "  + $c" }

if ($skipped.Count -gt 0) {
    Write-Output ''
    Write-Output ("Skipped {0} file(s) that already exist (not changed):" -f $skipped.Count)
    foreach ($s in $skipped) { Write-Output "  = $s" }
}

if ($gitignoreAdd.Count -gt 0) {
    Write-Output ''
    Write-Output 'Your .gitignore was left unchanged. Consider adding these lines to it:'
    foreach ($l in $gitignoreAdd) { Write-Output "  $l" }
}

# True if an adapters.txt has at least one enabled (non-comment) line.
function Test-AdaptersEnabled([string]$path) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
    foreach ($line in (Get-Content -LiteralPath $path)) {
        $t = ($line -replace '#.*$', '').Trim()
        if ($t) { return $true }
    }
    return $false
}

# Run "<py> .pmkit\pmkit.py <args>" in the target and pass its output on.
# Sets $script:pmkitOk to $true on exit 0 and $script:pmkitOut to the output
# text (a return value would be mixed into the output stream).
function Invoke-Pmkit($py, [string[]]$cmd) {
    $pmkitPath = Join-Path (Join-Path $targetFull '.pmkit') 'pmkit.py'
    $pyArgs = @($py | Select-Object -Skip 1) + @($pmkitPath) + $cmd
    $ok = $false
    $lines = New-Object System.Collections.Generic.List[string]
    Push-Location -LiteralPath $targetFull
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $py[0] @pyArgs 2>&1 | ForEach-Object { $lines.Add("$_"); Write-Output "$_" }
        $ok = ($LASTEXITCODE -eq 0)
    } catch {
        $ok = $false
    } finally {
        $ErrorActionPreference = $prevEap
        Pop-Location
    }
    $script:pmkitOk = $ok
    $script:pmkitOut = ($lines -join "`n")
}

# Ask y/N on the console. False when there is no console to ask.
function Read-YesNo([string]$question) {
    try {
        if ([Console]::IsInputRedirected) { return $false }
        $a = Read-Host $question
        return ($a -match '^(y|yes)$')
    } catch {
        return $false
    }
}

# Prune routing lines that point to files not copied, then sync adapters if
# any are enabled. Runs only when .pmkit\ was copied in this run.
if ($created -contains '.pmkit/pmkit.py') {
    $py = $null
    foreach ($candText in @('python3', 'python', 'py -3')) {
        $cand = @($candText -split ' ')
        if (-not (Get-Command $cand[0] -CommandType Application -ErrorAction SilentlyContinue)) { continue }
        # Windows Store stubs for python/python3 exist on PATH but fail, so
        # run each candidate instead of only looking it up.
        $candArgs = @($cand | Select-Object -Skip 1) + @('-c', 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)')
        try {
            & $cand[0] @candArgs *> $null
            if ($LASTEXITCODE -eq 0) { $py = $cand; break }
        } catch { }
    }
    $pyShow = 'python'
    if ($null -ne $py) { $pyShow = ($py -join ' ') }
    if ($DryRun) {
        $adapters = Join-Path (Join-Path $srcFull '.pmkit') 'adapters.txt'
    } else {
        $adapters = Join-Path (Join-Path $targetFull '.pmkit') 'adapters.txt'
    }
    $runSync = Test-AdaptersEnabled $adapters
    Write-Output ''
    if ($DryRun) {
        Write-Output "Would run in ${targetFull}: $pyShow .pmkit\pmkit.py prune --dry-run, then prune after a yes"
        if ($runSync) {
            Write-Output "Would run in ${targetFull}: $pyShow .pmkit\pmkit.py sync"
        } else {
            Write-Output 'Would not run sync: no adapter is enabled in .pmkit\adapters.txt.'
        }
    } elseif ($null -eq $py) {
        Write-Output 'Python 3.8+ was not found, so nothing was pruned.'
        Write-Output "Install Python 3, then run this in ${targetFull}:"
        Write-Output '  python .pmkit\pmkit.py prune'
        if ($runSync) { Write-Output '  python .pmkit\pmkit.py sync' }
    } else {
        Write-Output "Running in ${targetFull}: $pyShow .pmkit\pmkit.py prune --dry-run"
        Invoke-Pmkit $py @('prune', '--dry-run')
        if (-not $script:pmkitOk) {
            Write-Output "prune reported a problem (see above). Fix it, then run in ${targetFull}:"
            Write-Output "  $pyShow .pmkit\pmkit.py prune"
        } elseif (-not $script:pmkitOut.StartsWith('nothing to prune')) {
            $doPrune = $false
            if ($Yes) {
                $doPrune = $true
            } elseif ([Console]::IsInputRedirected) {
                Write-Output 'No console to ask and no -Yes.'
            } else {
                $doPrune = Read-YesNo 'Remove these lines now? [y/N]'
            }
            if ($doPrune) {
                Write-Output "Running in ${targetFull}: $pyShow .pmkit\pmkit.py prune"
                Invoke-Pmkit $py @('prune')
                if (-not $script:pmkitOk) {
                    Write-Output "prune reported a problem (see above). Fix it, then run in ${targetFull}:"
                    Write-Output "  $pyShow .pmkit\pmkit.py prune"
                }
            } else {
                Write-Output "Nothing was pruned. To prune later, run in ${targetFull}:"
                Write-Output "  $pyShow .pmkit\pmkit.py prune"
            }
        }
        if ($runSync) {
            Write-Output "Running in ${targetFull}: $pyShow .pmkit\pmkit.py sync"
            Invoke-Pmkit $py @('sync')
            if (-not $script:pmkitOk) {
                Write-Output "sync reported a problem (see above). Fix it, then run in ${targetFull}:"
                Write-Output "  $pyShow .pmkit\pmkit.py sync"
            }
        } else {
            Write-Output 'No adapter is enabled in .pmkit\adapters.txt, so sync was not run.'
        }
    }
}

if ($created -contains 'README.md') {
    $readmeHint = 'README.md in this folder says what each file is for (delete it after reading).'
} else {
    $readmeHint = "What each file is for: $repoUrl/blob/main/template/README.md"
}
$hasPmkit = ($created -contains '.pmkit/pmkit.py') -or (Test-Path -LiteralPath (Join-Path (Join-Path $targetFull '.pmkit') 'pmkit.py'))

# A filled-in SETUP_DECISIONS.md means the interview already ran (this script
# was called after it), so do not tell the user to run it again.
$setupPath = Join-Path $targetFull 'SETUP_DECISIONS.md'
$interviewed = $false
if (Test-Path -LiteralPath $setupPath -PathType Leaf) {
    $interviewed = -not (Select-String -LiteralPath $setupPath -SimpleMatch -Quiet -Pattern '<short name>')
}

Write-Output ''
Write-Output 'Next steps:'
if ($interviewed) {
    Write-Output '  1. Files created. Fill PROJECT.md (and any other placeholders) with your agent.'
    Write-Output "  2. $readmeHint"
} else {
    Write-Output '  1. Run the interview (Claude Code skill "project-setup", or paste a level''s RUNFILE.md into any LLM).'
    Write-Output "  2. Delete the files the interview did not justify. $readmeHint"
}
if ($created -contains 'RULES.md') {
    Write-Output '     RULES.md holds the working rules. Edit it to fit. To trim it, delete whole sections:'
    Write-Output '     "## Code" for a project with no code; "## Agent" and "## Code" if you only use a chat window.'
}
if ($hasPmkit) {
    Write-Output '  3. If you keep .pmkit\: after deleting files run "python .pmkit\pmkit.py prune".'
    Write-Output '     Enable an adapter in .pmkit\adapters.txt only for a tool that does not read AGENTS.md'
    Write-Output '     (for Claude Code: "CLAUDE.md import"), then run "python .pmkit\pmkit.py sync".'
    Write-Output '     Run "python .pmkit\pmkit.py check" to confirm the folder is consistent.'
} else {
    Write-Output '  3. Without .pmkit/, remove by hand any line ending in "<!-- needs: X -->" whose X you did not keep.'
}
