[CmdletBinding()]
param ()

Import-Module "./tests/bin/helpers/utils.psm1"
$ErrorActionPreference = "Stop"

Write-Green "Test default installation"
& ./bin/install_spcache.ps1 1>$null

Write-Green "Test that spcache is present in the persistent and session paths"
Test-SpcacheInPath

Write-Green "Test that invalid files return the correct exit code"
Invoke-NativeCommand 'spcache set --file .gitattributes'
if ($LASTEXITCODE -ne 3) {
  throw "$LASTEXITCODE"
}

Write-Green "Test that spcache detects the prefs file (Windows Store Installations)"
New-Item -Force `
~/AppData/Local/Packages/SpotifyAB.SpotifyMusic_foobar/LocalState/Spotify/prefs *>$null

spcache set --size 200 --yes 1>$null
if ($LASTEXITCODE -ne 0) {
  throw "$LASTEXITCODE"
}

Write-Green "Test that spcache reads from the same prefs file"
$output = spcache get --yes
if ($LASTEXITCODE -ne 0) {
    throw "$LASTEXITCODE"
}
if ($output -notlike "*200*") {
    throw "$output"
}

$persistent_path = [Environment]::GetEnvironmentVariable(
    "PATH",
    [EnvironmentVariableTarget]::User
)
$session_path = $env:PATH

Write-Green "Test installation of an invalid version"
try {
    & ./bin/install_spcache.ps1 -Version foobar *>$null
    throw "An error should've occured."
} catch {
    $_
}

Write-Green "Test installation of a valid version"
& ./bin/install_spcache.ps1 -Version 1.0.0 1>$null
Test-SpcacheVersion "1.0.0"

Write-Green "Test that the new installation hasn't changed any paths"
Test-PathHasntChanged $persistent_path $session_path

Write-Green "Test uninstallation"
& ./bin/uninstall_spcache.ps1 -NoConfirm 1>$null

Write-Green "Test that spcache has been removed from the persistent and session paths"
Test-SpcacheNotInPath

Write-Green "Test that uninstallation doesn't prompt when spcache isn't installed"
& ./bin/uninstall_spcache.ps1 1>$null

Write-Green "All tests passed!"
