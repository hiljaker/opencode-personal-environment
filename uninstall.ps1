$ErrorActionPreference = 'Stop'

if ($env:XDG_CONFIG_HOME) {
    $ConfigBase = $env:XDG_CONFIG_HOME
} else {
    $ConfigBase = Join-Path $HOME '.config'
}
$ConfigDir = Join-Path $ConfigBase 'opencode'
$StateFile = Join-Path $ConfigDir '.personal-opencode-environment-state.json'

if (-not (Test-Path $StateFile)) {
    Write-Host "No installation state found at: $StateFile"
    exit 0
}

$State = Get-Content $StateFile -Raw | ConvertFrom-Json
$Removed = 0
foreach ($relative in $State.files) {
    $target = Join-Path $ConfigDir $relative
    if (Test-Path $target -PathType Leaf) {
        Remove-Item -Force $target
        $Removed++
    }
}

# Remove empty directories from deepest to shallowest, without touching config root.
$dirs = @($State.files | ForEach-Object { Split-Path (Join-Path $ConfigDir $_) -Parent } | Sort-Object -Unique)
foreach ($dir in $dirs | Sort-Object Length -Descending) {
    while ($dir -and $dir -ne $ConfigDir -and (Test-Path $dir)) {
        if ((Get-ChildItem -Force $dir | Select-Object -First 1)) { break }
        Remove-Item -Force $dir
        $dir = Split-Path $dir -Parent
    }
}

Remove-Item -Force $StateFile
Write-Host 'OpenCode environment uninstalled.'
Write-Host "  Removed files: $Removed"
Write-Host "  Backups remain under: $(Join-Path $ConfigBase 'opencode-backups')"
