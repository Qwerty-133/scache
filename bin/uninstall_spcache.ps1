<#
.SYNOPSIS
    Uninstalls spcache.
.DESCRIPTION
    This script removes the spcache executable and removes it from the PATH.
.PARAMETER NoConfirm
    If specified, the script will not prompt for confirmation.
.EXAMPLE
    uninstall_spcache

    uninstall_spcache -N
.LINK
    https://github.com/Qwerty-133/spcache
.NOTES
    Author: Qwerty-133
    License: MIT
#>

[CmdletBinding()]
param(
    [Alias("N")]
    [switch]$NoConfirm
)

$ErrorActionPreference = "Stop"

$BASE_DIR = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
$APP_DIR = "$BASE_DIR\spcache"

if (-not (Test-Path $APP_DIR)) {
    Write-Warning "spcache is not currently installed."
    return
}

if (-not $NoConfirm) {
    $confirm = Read-Host "Are you sure you want to uninstall spcache? [Y/n]"
    $valid = @("y", "yes", "true", "t", "on", "1")
    if (-not $valid.Contains($confirm.ToLower())) {
        Write-Host "Aborted!" -ForegroundColor Red
        return
    }
}

$PersistentPath = [Environment]::GetEnvironmentVariable(
    "PATH",
    [EnvironmentVariableTarget]::User
)
$PersistentPath = $PersistentPath -split ";" | Where-Object { $_ }

$SessionPath = $env:PATH -split ";" | Where-Object {
    $_ -and ($_ -ne $APP_DIR)
}
$env:PATH = $SessionPath -join ";"

if ($PersistentPath -contains $APP_DIR) {
    $PersistentPath = $PersistentPath | Where-Object { $_ -ne $APP_DIR }
    $PersistentPath += ""

    [Environment]::SetEnvironmentVariable(
        "PATH",
        $PersistentPath -join ";",
        [EnvironmentVariableTarget]::User
    )
    Write-Host "Removed $APP_DIR from PATH" -ForegroundColor Cyan
}

# From https://stackoverflow.com/a/9012108/14803382
try {
    Get-ChildItem -Path $APP_DIR -Recurse | Remove-Item -Force -Recurse
} catch {
    Write-Debug "Get-ChildItem pipe failed."
}
try {
    Remove-Item $APP_DIR -Force -Recurse
} catch {
    Write-Debug "Remove-Item failed."
}
if (Test-Path $APP_DIR) {
    Write-Error "Failed to delete $APP_DIR, please delete it manually."
} else {
    Write-Host "Successfully uninstalled spcache." -ForegroundColor Green
}
