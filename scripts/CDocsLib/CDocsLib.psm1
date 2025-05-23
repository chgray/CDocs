
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

    # Write-Host ""
    # Write-Host ""
    # Write-Host ""
    # Write-Host "Starting Container] ----------------------------------------------------------------"
    # Write-Host "ContainerLauncher : $ContainerLauncher"
    # Write-Host "Container : $Container"
    # Write-Host "DebugMode: $DebugMode"

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
        #Write-Host "Mapping : [$mapping]"
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

    # Write-Host "      Arguments : [$ContainerLauncher $argString]"
    # Write-Host "   PROJECT_ROOT : [$PROJECT_ROOT]"

    if($DebugMode) {
        Write-Host "Debug Arguments : [$ContainerLauncher $debugArgs]"
        Start-Process -NoNewWindow -FilePath $ContainerLauncher -Wait -ArgumentList $debugArgs
        Write-Error "EXITING : Debug Mode is enabled"
        exit 1
    } else {
    #    Write-Host "A[$toolArgs]"
    #    Write-Host "B["+($toolArgs.ToArray())+"]"
        Start-Process -NoNewWindow -FilePath $ContainerLauncher -Wait -ArgumentList $toolArgs.ToArray()
    }
}

function Get-CDocs.Container.Tool
{
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
    #Write-Host "Making $Path relative to $Base"

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
    #Write-Host "Making $Path relative to $Base"

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


function Get-Temp.File {
    param (
        [Parameter(Mandatory = $true)]
        [string]$File,

        [Parameter(Mandatory = $true)]
        [string]$Op,

        [Parameter(Mandatory = $false)]
        [switch]$Linux = $false
    )

    $ErrorActionPreference = 'Break'

    #  Write-Host ""
    #  Write-Host ""
    #  Write-Host "Seeking Temp File ---------------------------------------------"
    #  Write-Host "         Input : $File"
    #  Write-Host "            Op : $Op"
    #  Write-Host "         Linux : $Linux"
    #  Write-Host "           PWD : $PWD"

    if (!(Test-Path -Path $File)) {
        $createdFileOnStart = New-Item -Path $File -ItemType file
    }

    $File_FullPath = Resolve-Path -Path $File
    # Write-Host "        FInput : $File_FullPath"
    # Write-Host " File_FullPath : $File_FullPath"

    #
    # Locate our temp folder, by seeking our root config
    #
    $CDOC_ROOT = $PWD
    while (![string]::IsNullOrEmpty($CDOC_ROOT)) {
        $root = Join-Path -Path $CDOC_ROOT -ChildPath ".CDocs.config"
        if (Test-Path -Path $root) {
            break
        }
        $CDOC_ROOT = Split-Path -Path $CDOC_ROOT -Parent
    }
    if([string]::IsNullOrEmpty($CDOC_ROOT)) {
        Write-Error "Unable to locate CDocs project root"
        exit 1
    }

    #$CDOC_ROOT = Split-Path -Path $File -Parent

    $MY_PROJECT_ROOT = Split-Path -Path $File -Parent
    #$File_Relative = Resolve-Path -Path $File -RelativeBasePath $CDOC_ROOT -Relative

    #$TEMP_DIR = Join-Path -Path $CDOC_ROOT -ChildPath "cdocs-temp"
    $TEMP_DIR = $CDOC_ROOT

    if (!(Test-Path -Path $TEMP_DIR)) {
        #Write-Host "Creating temp directory"
        $ni = New-Item -Path $TEMP_DIR -ItemType directory
    }

    # Write-Host "  MY_PROJECT_ROOT : $MY_PROJECT_ROOT"
    # Write-Host "        TEMP_DIR : $TEMP_DIR"

    #
    # Create temp file name
    #
    $fileHelper = Get-Item $File
    $extension = $fileHelper.Extension

    $fileName = Split-Path -Path $File -Leaf

    if($Linux)
    {
        $tempFile = "./$fileName"
    } else {
        $tempFile = Join-Path -Path $MY_PROJECT_ROOT -ChildPath $fileName
    }

    $tempFile = $tempFile + ".tmp.$Op"

    # Write-Host ""
    # Write-Host ""
    # Write-Host ""

    if($Linux) {

        #$parentDir = Split-Path -Path $tempFile -Leaf

        # Write-Host "      CDOC_ROOT : $CDOC_ROOT"
        # Write-Host "MY_PROJECT_ROOT : $MY_PROJECT_ROOT"
        # Write-Host "       TempFile : $tempFile"
        $tempFile_combined = Join-Path -Path $MY_PROJECT_ROOT -ChildPath $tempFile

        if (!(Test-Path -Path $tempFile_combined)) {
            $ni = New-Item -Path $tempFile_combined -ItemType file
        }

        #Write-Host "       TempFile : $tempFile"
        $tempFile = Resolve-Path -Path $tempFile -RelativeBasePath $MY_PROJECT_ROOT -Relative
        #Write-Host "TempFile_shrunk : $tempFile"


        if ($ni -ne $null) {
            $oi = Remove-Item -Path $tempFile_combined
        }
        $tempFile = $tempFile -replace '\\', '/'
    }

    if ($createdFileOnStart) {
        $oi = Remove-Item -Path $File
    }
    #Write-Host "      TempFile : $tempFile"
    $tempFile
}


Export-ModuleMember -Function *