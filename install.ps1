$ErrorActionPreference = 'Stop'

$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManifestPath = Join-Path $Repo 'manifest.json'
$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

if ($env:XDG_CONFIG_HOME) {
    $ConfigBase = $env:XDG_CONFIG_HOME
} else {
    $ConfigBase = Join-Path $HOME '.config'
}
if ($env:OPENCODE_CONFIG_DIR) {
    $ConfigDir = $env:OPENCODE_CONFIG_DIR
} else {
    $ConfigDir = Join-Path $ConfigBase 'opencode'
}
$BackupRoot = Join-Path $ConfigBase 'opencode-backups'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir = Join-Path $BackupRoot $Timestamp
$StateFile = Join-Path $ConfigDir '.personal-opencode-environment-state.json'

New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

$SourceFiles = New-Object System.Collections.Generic.List[string]
foreach ($relative in $Manifest.managed.files) {
    $SourceFiles.Add($relative)
}
$SeedFiles = @()
if ($Manifest.managed.seed) {
    $SeedFiles = @($Manifest.managed.seed)
}
foreach ($directory in $Manifest.managed.directories) {
    $sourceDir = Join-Path $Repo $directory
    if (Test-Path $sourceDir) {
        Get-ChildItem -Path $sourceDir -Recurse -File | ForEach-Object {
            $relative = $_.FullName.Substring($Repo.Length + 1).Replace('\', '/')
            $SourceFiles.Add($relative)
        }
    }
}

$BackedUp = 0
foreach ($relative in $SourceFiles) {
    $source = Join-Path $Repo $relative
    if (-not (Test-Path $source -PathType Leaf)) {
        throw "Managed source file missing: $relative"
    }
    $destination = Join-Path $ConfigDir $relative
    if (Test-Path $destination) {
        $backup = Join-Path $BackupDir $relative
        New-Item -ItemType Directory -Force -Path (Split-Path $backup) | Out-Null
        Copy-Item -Force $destination $backup
        $BackedUp++
    }
}

foreach ($relative in $SourceFiles) {
    $source = Join-Path $Repo $relative
    $destination = Join-Path $ConfigDir $relative
    New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
    Copy-Item -Force $source $destination
}

# Seed files are written only when missing. opencode.jsonc may contain
# machine-local MCP configuration, so updates must not replace it.
foreach ($relative in $SeedFiles) {
    $source = Join-Path $Repo $relative
    $destination = Join-Path $ConfigDir $relative
    if (-not (Test-Path $source -PathType Leaf)) {
        throw "Seed source file missing: $relative"
    }
    if (-not (Test-Path $destination)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
        Copy-Item -Force $source $destination
    }
}

$State = [ordered]@{
    schemaVersion = 1
    repository = $Repo
    installedAt = (Get-Date).ToUniversalTime().ToString('o')
    files = @($SourceFiles)
}
$State | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 $StateFile

Write-Host 'OpenCode environment installed.'
Write-Host "  Config:  $ConfigDir"
Write-Host "  Files:   $($SourceFiles.Count)"
Write-Host "  Seed:    $($SeedFiles.Count) (written only when missing)"
Write-Host "  Backup:  $BackupDir"
Write-Host "  Existing managed files backed up: $BackedUp"
Write-Host ''
Write-Host 'Next: authenticate providers locally in OpenCode (for example, /connect), then choose a model with /models.'
Write-Host 'Optional MCP/skill checklist is available in the bash installer; PowerShell support is pending.'
