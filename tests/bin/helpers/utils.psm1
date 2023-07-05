[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[CmdletBinding()]
param ()

$GITHUB_TOKEN = $env:GITHUB_TOKEN
if ([string]::IsNullOrWhiteSpace($GITHUB_TOKEN)) {
    Write-Verbose "No GitHub token found in environment variables."
    $headers = @{ }
}
else {
    $headers = @{ "Authorization" = "Bearer $GITHUB_TOKEN" }
}

function Write-Green {
    <#
    .SYNOPSIS
        Write a message to the console in green text.
    .PARAMETER Message
        The message to write to the console.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host $Message -ForegroundColor Green
}


function Test-SpcacheInPath {
    <#
    .SYNOPSIS
        Test that spcache is present in the persistent and session paths.
    .NOTES
        This will always fail on Unix systems.
    #>
    [CmdletBinding()]
    param ()

    $PERSISTENT_PATH = [Environment]::GetEnvironmentVariable(
        "PATH",
        [EnvironmentVariableTarget]::User
    )
    if ($PERSISTENT_PATH -notlike "*spcache*") {
        throw "spcache couldn't be found in the persistent PATH"
    }

    if ($env:PATH -notlike "*spcache*") {
        throw "spcache couldn't be found in the session PATH"
    }
}


function Test-SpcacheNotInPath {
    <#
    .SYNOPSIS
        Test that spcache is not present in the persistent or session path.
    #>
    [CmdletBinding()]
    param ()

    $PERSISTENT_PATH = [Environment]::GetEnvironmentVariable(
        "PATH",
        [EnvironmentVariableTarget]::User
    )
    if ($PERSISTENT_PATH -like "*spcache*") {
        throw "spcache is still present in the persistent PATH"
    }

    if ($env:PATH -like "*spcache*") {
        throw "spcache is still present in the session PATH"
    }
}


function Test-SpcacheVersion {
    <#
    .SYNOPSIS
        Test that spcache's version matches the provided version.
    .PARAMETER Version
        The version to compare against.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $actual_version = spcache --version
    if ($LASTEXITCODE -ne 0) {
        throw "$LASTEXITCODE"
    }
    if ($actual_version -notlike "*$Version*") {
        throw "$actual_version"
    }
}


function Test-PathHasntChanged {
    <#
    .SYNOPSIS
        Test that the session and persistent paths haven't changed.
    .PARAMETER PersistentPath
        The persistent path before the installation.
    .PARAMETER SessionPath
        The session path before the installation.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PersistentPath,
        [Parameter(Mandatory = $true)]
        [string]$SessionPath
    )

    $current_persistent_path = [Environment]::GetEnvironmentVariable(
        "PATH",
        [EnvironmentVariableTarget]::User
    )
    if ($current_persistent_path -ne $PersistentPath) {
        throw "Persistent path has changed"
    }
    if ($env:PATH -ne $SessionPath) {
        throw "Session path has changed"
    }
}


function Invoke-NativeCommand {
    <#
        .SYNOPSIS
            Ensure failing native commands don't terminate the script.
        .DESCRIPTION
            Windows Powershell has this issue, in which case the command is run inside cmd.exe.
        .PARAMETER Command
            The command to run.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    if ($PSVersionTable.PSEdition -eq "Desktop") {
        $Command = "cmd /c $Command"
    }
    else {
        $Command = "$Command *>$$null"
    }

    Invoke-Expression $Command
}


Export-ModuleMember -Function * -Alias * -Variable *
