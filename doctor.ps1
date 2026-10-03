$ErrorActionPreference = 'Stop'

$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$Checks = @(
    @{ Name = 'manifest exists'; Path = (Join-Path $Repo 'manifest.json') },
    @{ Name = 'AGENTS.md exists'; Path = (Join-Path $Repo 'AGENTS.md') },
    @{ Name = 'opencode.jsonc exists'; Path = (Join-Path $Repo 'opencode.jsonc') },
    @{ Name = 'cli.json exists'; Path = (Join-Path $Repo 'cli.json') }
)
$Failed = $false
foreach ($check in $Checks) {
    if (Test-Path $check.Path) {
        Write-Host "PASS  $($check.Name)"
    } else {
        Write-Host "FAIL  $($check.Name)"
        $Failed = $true
    }
}

$skillsDir = Join-Path $Repo 'skills'
Get-ChildItem -Path $skillsDir -Recurse -Filter 'SKILL.md' | ForEach-Object {
    $skillDir = Split-Path $_.DirectoryName -Leaf
    if ($skillDir -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        Write-Host "FAIL  invalid skill directory: $skillDir"
        $Failed = $true
    }
}

$skillText = (Get-ChildItem $skillsDir -Recurse -Filter 'SKILL.md' | Get-Content -Raw) -join "`n"
if ($skillText -match '(?i)ayopajak|purwadhika|garda bina utama|\btax\b|\bpajak\b|e[- ]?faktur|e[- ]?bupot|\bcoretax\b|\bpjap\b') {
    Write-Host 'FAIL  project/domain-specific references detected in skills'
    $Failed = $true
} else {
    Write-Host 'PASS  skills contain no known project/domain-specific references'
}

if (Get-Command opencode -ErrorAction SilentlyContinue) {
    try { Write-Host "INFO  OpenCode: $(& opencode --version)" } catch { Write-Host 'INFO  OpenCode found but version unavailable' }
} else {
    Write-Host 'INFO  OpenCode CLI not found on PATH'
}

if ($Failed) { exit 1 }
Write-Host '`nDoctor check completed successfully.'
