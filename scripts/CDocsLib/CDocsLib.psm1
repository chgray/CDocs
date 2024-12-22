
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
    $toolArgs = New-Object System.Collections.Generic.List[string]

    #
    # Build 'real' arguments
    #
    $toolArgs.Add("run")
    $toolArgs.Add("-it")
    $toolArgs.Add("--rm")

    #
    # Process folder mappings
    #
    foreach($mapping in $DirectoryMappings) {
        Write-Host "Mapping : [$mapping]"
        $toolArgs.Add("-v")
        $toolArgs.Add($mapping)
    }

    #
    # Data directory mapping
    #
    $PROJECT_ROOT=Get-CDocs.ProjectRoot
    $toolArgs.Add("-v")
    $toolArgs.Add($PROJECT_ROOT + ":/data")

    #
    # Add the container, and then args
    #
    $toolArgs.Add($Container)
    $toolArgs.Add($WorkingDir)
    $toolArgs.Add($ArgumentList)

    foreach ($arg in $toolArgs) {
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
    Write-Host "   PROJECT_ROOT : [$PROJECT_ROOT]"

    if($DebugMode) {
        Write-Host "Debug Arguments : [$ContainerLauncher $debugArgs]"
        Start-Process -NoNewWindow -FilePath $ContainerLauncher -Wait -ArgumentList $debugArgs
        Write-Error "EXITING : Debug Mode is enabled"
        exit 1
    } else {
        Write-Host "A[$toolArgs]"
        Write-Host "B["+($toolArgs.ToArray())+"]"
        Start-Process -NoNewWindow -FilePath $ContainerLauncher -Wait -ArgumentList $toolArgs.ToArray()
    }
}

function Get-CDocs.Container.Tool {

    Write-Host "Discovering Container Tool  ] ---------------------------------------------"
    $temp = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
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
            $process = (Start-Process -NoNewWindow -FilePath "podman" -Wait -ErrorAction SilentlyContinue -PassThru -ArgumentList "-v")

            if ($process.ExitCode -ne 0) {
                throw "podman failed with exit code $($process.ExitCode)"
            }
            $ret="podman"
        } catch {
        } finally {
        }
    }
    $ErrorActionPreference = $temp
    $ret
}

function Get-CDocs.ProjectRoot {
    #
    # Locate the CDocs project root
    #
    $PROJECT_ROOT = $PWD.Path
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


function Convert-Path.To.LinuxRelativePath.BUGGY{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Base
    )
    Write-Host "Making $Path relative to $Base"

    if (!(Test-Path -Path $Path)) {
        $Path = $Path.Substring($Base.Length)
        $Path = $Path -replace '\\', '/'
        $Path = "." + $Path
        $Path
    } else {
        $Ret = Resolve-Path -Path $Path -RelativeBasePath $Base -Relative
        $Ret = $Ret -replace '\\', '/'
        $Ret
    }
}

function Convert-LocalPath.To.CDocContainerPath{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Base
    )
    Write-Host "Making $Path relative to $Base"

    if (!(Test-Path -Path $Path)) {
        $Path = $Path.Substring($Base.Length)
        $Path = $Path -replace '\\', '/'
        $Path = "/data/" + $Path
        $Path
    } else {
        $Ret = Resolve-Path -Path $Path -RelativeBasePath $Base -Relative
        $Ret = $Ret -replace '\\', '/'
        $Ret = "/data/" + $Ret
        $Ret
    }
}

Export-ModuleMember -Function *