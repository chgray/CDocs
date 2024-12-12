
function Start-CDocs.Container {
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
    # Data directory mapping
    #
    $PROJECT_ROOT=Get-CDocs.ProjectRoot
    $args += "-v"
    $args += $PROJECT_ROOT + ":/data"

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

function Get-CDocs.Container.Tool {

    Write-Host "Discovering Container Tool  ] ---------------------------------------------"

    try {
        $process = Start-Process -NoNewWindow -FilePath "docker" -Wait -ErrorAction SilentlyContinue -PassThru -ArgumentList "-v"

        if ($process.ExitCode -ne 0) {
            throw "docker failed with exit code $($process.ExitCode)"
        }
        $ret="docker"
    } catch {
    } finally {
    }

    if ($CONTAINER_TOOL -eq $null) {
        try {
            $process = Start-Process -NoNewWindow -FilePath "podman" -Wait -ErrorAction SilentlyContinue -PassThru -ArgumentList "-v"

            if ($process.ExitCode -ne 0) {
                throw "podman failed with exit code $($process.ExitCode)"
            }
            $ret="podman"
        } catch {
        } finally {
        }
    }
    $ret
}

function Get-CDocs.ProjectRoot {
    #
    # Locate the CDocs project root
    #
    $PROJECT_ROOT = $PWD
    while (![string]::IsNullOrEmpty($PROJECT_ROOT)) {
        $root = Join-Path -Path $PROJECT_ROOT -ChildPath ".CDocs.config"
        if (Test-Path -Path $root) {
            break
        }
        $PROJECT_ROOT = Split-Path -Path $PROJECT_ROOT -Parent
    }
    if([string]::IsNullOrEmpty($PROJECT_ROOT)) {
        Write-Error "Unable to locate .CDocs.config project root"
        exit 1
    }

    $PROJECT_ROOT
}


Export-ModuleMember -Function *