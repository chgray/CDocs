
function Start-CDocContainer {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkingDir,

        [Parameter(Mandatory = $false)]
        [switch]$DebugMode = $false,

        [Parameter(Mandatory = $true)]
        [string]$ContainerLauncher,

        [Parameter(Mandatory = $true)]
        [string]$Container,

        [Parameter(Mandatory = $false)]
        [string[]]$DirectoryMappings,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "Starting Container] ----------------------------------------------------------------"
    Write-Host "ContainerLauncher : $ContainerLauncher"
    Write-Host "Container : $Container"
    Write-Host "DebugMode: $DebugMode"

    $argString = ""
    $args = @()

    #
    # Build 'real' arguments
    #
    $args += "run"
    $args += "-it"
    $args += "--rm"

    #
    # Process folder mappings
    #
    foreach($mapping in $DirectoryMappings) {
        Write-Host "Mapping : [$mapping]"
        $args += "-v"
        $args += $mapping
    }

    #
    # Add the container, and then args
    #
    $args += $Container
    $args += $WorkingDir
    $args += $ArgumentList

    foreach ($arg in $args) {
        $argString += $arg + " "
    }


    # -------------------------------------
    $debugArgs = @()
    $debugArgsString = ""
    $debugArgs += "run"
    $debugArgs += "-it"
    $debugArgs += "--rm"

    #
    # Process folder mappings
    #
    foreach($mapping in $DirectoryMappings) {
        $debugArgs += "-v"
        $debugArgs += $mapping
    }

    #
    # Add the container, and then args
    #
    $debugArgs += "ubuntu:latest"

    Write-Host "      Arguments : [$ContainerLauncher $argString]"

    if($DebugMode) {
        Write-Host "Debug Arguments : [$ContainerLauncher $debugArgs]"
        Start-Process -NoNewWindow -FilePath $ContainerLauncher -Wait -ArgumentList $debugArgs
        Write-Error "EXITING : Debug Mode is enabled"
        exit 1
    } else {
        Start-Process -NoNewWindow -FilePath $ContainerLauncher -Wait -ArgumentList $args
    }
}



Export-ModuleMember -Function Start-CDocContainer