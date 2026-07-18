param(
    [string]$AshitaRoot = "C:\Games\CatsEyeXI\catseyexi-client\Ashita",
    [switch]$Force,
    [switch]$SkipAutoload
)

$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "ashitaframes"
$target = Join-Path $AshitaRoot "addons\ashitaframes"
$startupScript = Join-Path $AshitaRoot "scripts\default.txt"
$autoloadLine = "/addon load ashitaframes"
$backupRoot = Join-Path $PSScriptRoot ".local-backups"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $backupRoot $timestamp
$startupBackup = $null
$autoloadStatus = "skipped"

if (-not (Test-Path -LiteralPath $source)) {
    throw "Source addon folder does not exist: $source"
}

if (-not (Test-Path -LiteralPath $AshitaRoot)) {
    throw "Ashita root does not exist: $AshitaRoot"
}

New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

if (Test-Path -LiteralPath $target) {
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    Copy-Item -LiteralPath $target -Destination (Join-Path $backup "ashitaframes") -Recurse -Force

    if (-not $Force) {
        Write-Host "Existing addon backed up to: $backup"
    }
}

if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}

Copy-Item -LiteralPath $source -Destination $target -Recurse -Force

if (-not $SkipAutoload) {
    if (Test-Path -LiteralPath $startupScript) {
        $autoloadLineLower = $autoloadLine.ToLowerInvariant()
        $hasAutoload = $false
        foreach ($line in Get-Content -LiteralPath $startupScript) {
            if ($line.Trim().ToLowerInvariant() -eq $autoloadLineLower) {
                $hasAutoload = $true
                break
            }
        }

        if ($hasAutoload) {
            $autoloadStatus = "already present in: $startupScript"
        } else {
            if (-not (Test-Path -LiteralPath $backup)) {
                New-Item -ItemType Directory -Force -Path $backup | Out-Null
            }

            $startupBackup = Join-Path $backup "default.txt"
            Copy-Item -LiteralPath $startupScript -Destination $startupBackup -Force
            Add-Content -LiteralPath $startupScript -Value $autoloadLine
            $autoloadStatus = "added to: $startupScript"
        }
    } else {
        $autoloadStatus = "not added; startup script not found: $startupScript"
    }
}

$startupBackupForRollback = ""
if ($startupBackup -ne $null) {
    $startupBackupForRollback = $startupBackup
}

$rollback = Join-Path $backupRoot "rollback-$timestamp.ps1"
$rollbackContent = @"
`$ErrorActionPreference = "Stop"
`$target = "$target"
`$backupAddon = "$(Join-Path $backup "ashitaframes")"
`$startupScript = "$startupScript"
`$startupBackup = "$startupBackupForRollback"

if (Test-Path -LiteralPath `$target) {
    Remove-Item -LiteralPath `$target -Recurse -Force
}

if (Test-Path -LiteralPath `$backupAddon) {
    Copy-Item -LiteralPath `$backupAddon -Destination `$target -Recurse -Force
    Write-Host "Restored previous ashitaframes addon."
} else {
    Write-Host "Removed ashitaframes addon. No previous addon backup was present."
}

if (`$startupBackup -ne "" -and (Test-Path -LiteralPath `$startupBackup)) {
    Copy-Item -LiteralPath `$startupBackup -Destination `$startupScript -Force
    Write-Host "Restored previous Ashita startup script."
}
"@

Set-Content -LiteralPath $rollback -Value $rollbackContent -Encoding UTF8

Write-Host "Installed ashitaframes addon to: $target"
Write-Host "Autoload: $autoloadStatus"
Write-Host "Load now in game with: /addon load ashitaframes"
Write-Host "Rollback script: $rollback"

