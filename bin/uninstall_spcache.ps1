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

$CURRENT_PATH = [Environment]::GetEnvironmentVariable(
    "PATH",
    [EnvironmentVariableTarget]::User
)
$CURRENT_PATH = $CURRENT_PATH -split ";" | Where-Object { $_ }

$CURRENT_SESSION_PATH = $env:PATH -split ";" | Where-Object {
    $_ -and ($_ -ne $APP_DIR)
}
$env:PATH = $CURRENT_SESSION_PATH -join ";"

if ($CURRENT_PATH -contains $APP_DIR) {
    $CURRENT_PATH = $CURRENT_PATH | Where-Object { $_ -ne $APP_DIR }
    $CURRENT_PATH += ""

    [Environment]::SetEnvironmentVariable(
        "PATH",
        $CURRENT_PATH -join ";",
        [EnvironmentVariableTarget]::User
    )
    Write-Host "Removed $APP_DIR from PATH" -ForegroundColor Cyan
}

Remove-Item -Path $APP_DIR -Force -Recurse | Out-Null
Write-Host "Successfully Uninstalled spcache." -ForegroundColor Green
