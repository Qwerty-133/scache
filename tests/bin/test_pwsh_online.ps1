[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
[CmdletBinding()]
param ()

Import-Module "./tests/bin/helpers/utils.psm1"
$ErrorActionPreference = "Stop"

$install_link = (
    "https://raw.githubusercontent.com/Qwerty-133/spcache-temp/main/bin/install_spcache.sh"
)
$uninstall_link = (
    "https://raw.githubusercontent.com/Qwerty-133/spcache-temp/main/bin/uninstall_spcache.ps1"
)

Write-Green "Test a basic installation using invoke-expression"
Invoke-WebRequest -UseBasicParsing -Headers $headers $install_link | Invoke-Expression

Write-Green "Test that spcache is present in the persistent path"
Test-SpcacheInPath

$persistent_path = [Environment]::GetEnvironmentVariable(
    "PATH",
    [EnvironmentVariableTarget]::User
)
$session_path = $env:PATH

Write-Green "Test script-block installation of a specific version"
$script = [scriptblock]::Create(
    (Invoke-WebRequest -UseBasicParsing Headers $headers $install_link).Content
)
& $script -Version 1.0.0
Test-SpcacheVersion "1.0.0"

Write-Green "Test that the persistent and session paths haven't changed"
Test-PathHasntChanged $persistent_path $session_path

Write-Green "Test script block uninstallation"
$script = [scriptblock]::Create(
    (Invoke-WebRequest -UseBasicParsing -Headers $headers $uninstall_link).Content
)

& $script -NoConfirm

Write-Green "Test that spcache has been removed from the persistent and session paths"
Test-SpcacheNotInPath

Write-Green "Test that uninstallation doesn't prompt when spcache isn't installed"
Invoke-WebRequest -UseBasicParsing -Headers $headers $uninstall_link | Invoke-Expression
