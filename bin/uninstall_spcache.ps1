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


function Remove-Path {
    <#
    .SYNOPSIS
        Remove the file/directory present at the supplied path.
    .PARAMETER Path
        The path to remove.
    .LINK
        https://stackoverflow.com/a/9012108/14803382
    #>
    [
        Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            "PSUseShouldProcessForStateChangingFunctions", ""
        )
    ]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath
    )
    try {
        Get-ChildItem -LiteralPath $LiteralPath -Recurse | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Force -Recurse
        }
    } catch {
        Write-Verbose "Get-ChildItem pipe failed."
    }
    try {
        Remove-Item -LiteralPath $LiteralPath -Force -Recurse
    } catch {
        Write-Verbose "Remove-Item failed."
    }
    if (Test-Path -LiteralPath $LiteralPath) {
        Write-Error "Failed to remove $LiteralPath"
    }
}


$BASE_DIR = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
$APP_DIR = "$BASE_DIR\spcache"
if (-not (Test-Path -LiteralPath $APP_DIR -PathType Container)) {
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

try {
    Remove-Path -LiteralPath $APP_DIR
    Write-Host "Successfully uninstalled spcache." -ForegroundColor Green
}
catch {
    Write-Error "Failed to delete $APP_DIR, please delete it manually."
}
