<#
.SYNOPSIS
    Installs spcache.
.DESCRIPTION
    This script can install spcache pre-built binaries.

    The pre-built binaries are downloaded from GitHub, and are added to the
    PATH.

    If the GITHUB_TOKEN environment variable is set, it will be used to
    authenticate with GitHub. This is useful if you are hitting the rate limit
    for unauthenticated requests.
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

if ([string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
    $headers = @{ }
}
else {
    Write-Verbose "Using GitHub token for authentication"
    $headers = @{ "Authorization" = "Bearer $env:GITHUB_TOKEN" }
}


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
$ZIP = "$APP_DIR\spcache_dist.zip"

if (Test-Path -LiteralPath $APP_DIR) {
    Write-Verbose "Removing $APP_DIR"
    Remove-Path -LiteralPath $APP_DIR
}
New-Item -Path $APP_DIR -ItemType Directory | Out-Null
Write-Verbose "Created directory"

if ($Version -eq "latest") {
    $release_url = "https://api.github.com/repos/Qwerty-133/spcache/releases/latest"
}
else {
    $release_url = "https://api.github.com/repos/Qwerty-133/spcache/releases/tags/v$Version"
}

Write-Verbose "Fetching release data from $release_url"
$release_data = Invoke-RestMethod -UseBasicParsing $release_url -Headers $headers
$actual_version = $release_data.tag_name
$asset_url = (
    $release_data.assets |
    Where-Object { $_.name -eq "spcache_windows.zip" } |
    Select-Object -ExpandProperty browser_download_url
)
if (-not $asset_url) {
    Write-Error "Could not find a Windows release asset for version $actual_version."
}

Write-Host "Downloading spcache ($actual_version)..." -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Uri $asset_url -Headers $headers -OutFile $ZIP
Write-Host "Extracting spcache files..." -ForegroundColor Cyan
Expand-Archive -LiteralPath $ZIP -DestinationPath $APP_DIR -Force
Remove-Item -LiteralPath $ZIP -Force

Write-Verbose "Testing spcache"
cmd /c "$APP_DIR\spcache.exe" --version 1>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host -ForegroundColor Red (
        "The installed spcache executable is corrupt, or unsupported on this system."
    )
    Write-Host -ForegroundColor Yellow (
        "Please install spcache from PyPI instead, see" +
        " https://github.com/Qwerty-133/spcache#installing-from-pypi"
    )
    Write-Error "Failed to install spcache."
}


$PersistentPath = [Environment]::GetEnvironmentVariable(
    "PATH",
    [EnvironmentVariableTarget]::User
)
$PersistentPath = $PersistentPath -split ";" | Where-Object { $_ }

if (-not ($PersistentPath -contains $APP_DIR)) {
    Write-Host "Adding $APP_DIR to PATH..." -ForegroundColor Cyan
    $PersistentPath += $APP_DIR
    $PersistentPath += ""
    [Environment]::SetEnvironmentVariable(
        "PATH",
        $PersistentPath -join ";",
        [EnvironmentVariableTarget]::User
    )
}
$SessionPath = $env:PATH -split ";" | Where-Object { $_ }
if (-not ($SessionPath -contains $APP_DIR)) {
    $SessionPath += "$APP_DIR"
    $SessionPath += ""
    $env:PATH = $SessionPath -join ";"
    Write-Verbose "Added $APP_DIR to the current session's PATH."
}

Write-Host "Successfully installed spcache." -ForegroundColor Green
Write-Host "Run 'spcache set' to set the cache limit."
