<#
.SYNOPSIS
    Installs spcache.
.DESCRIPTION
    This script can install spcache pre-built binaries.

    The pre-built binaries are downloaded from GitHub, and are added to the
    PATH.
.PARAMETER Version
    The version of spcache to install. This can be a semantic version
    (e.g. 1.0.0), or "latest" to install the latest version.
.EXAMPLE
    install_spcache

    install_spcache -V 1.0.0
.LINK
    https://github.com/Qwerty-133/spcache
.NOTES
    Author: Qwerty-133
    License: MIT
#>

[CmdletBinding()]
param(
    [ValidatePattern("^((\d+\.\d+\.\d+)|(latest))$")]
    [Alias("V")]
    [string]$Version = "latest"
)

$ErrorActionPreference = "Stop"

$BASE_DIR = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
$APP_DIR = "$BASE_DIR\spcache"

if (-not (Test-Path $APP_DIR)) {
    New-Item -Path $APP_DIR -ItemType Directory | Out-Null
    Write-Verbose "Created directory $APP_DIR"
}

if ($Version -eq "latest") {
    $release_url = "https://api.github.com/repos/Qwerty-133/spcache/releases/latest"
} else {
    $release_url = "https://api.github.com/repos/Qwerty-133/spcache/releases/tags/v$Version"
}

Write-Verbose "Fetching release data from $release_url"
$release_data = Invoke-RestMethod -UseBasicParsing $release_url
$actual_version = $release_data.tag_name

$asset_url = (
    $release_data.assets |
    Where-Object { $_.name -eq "spcache_windows.exe" } |
    Select-Object -ExpandProperty browser_download_url
)

if (-not $asset_url) {
    Write-Error "Could not find a Windows release asset for version $actual_version."
}

Write-Host "Downloading spcache ($actual_version)..." -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Uri $asset_url -OutFile "$APP_DIR\spcache.exe"

$CURRENT_PATH = [Environment]::GetEnvironmentVariable(
    "PATH",
    [EnvironmentVariableTarget]::User
)
$CURRENT_PATH = $CURRENT_PATH -split ";" | Where-Object { $_ }

if (-not ($CURRENT_PATH -contains $APP_DIR)) {
    Write-Host "Adding $APP_DIR to PATH..." -ForegroundColor Cyan

    $CURRENT_PATH += $APP_DIR
    $CURRENT_PATH += ""

    [Environment]::SetEnvironmentVariable(
        "PATH",
        $CURRENT_PATH -join ";",
        [EnvironmentVariableTarget]::User
    )
    $env:PATH += ";${APP_DIR}"
}

Write-Host "Successfully installed spcache." -ForegroundColor Green
Write-Host "Run 'spcache set' to set the cache limit."
