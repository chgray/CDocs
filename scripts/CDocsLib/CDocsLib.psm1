
function Start-CDocs.Container {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkingDir,

        [Parameter(Mandatory = $false)]
        [switch]$DebugMode,

        [Parameter(Mandatory = $true)]
        [string]$ContainerLauncher,

        [Parameter(Mandatory = $true)]
        [string]$Container,

        [Parameter(Mandatory = $true)]
        [string]$ContainerName,

        [Parameter(Mandatory = $false)]
        [string[]]$DirectoryMappings,

        [Parameter(Mandatory = $false)]
        [switch]$Privileged  = $false,

        [Parameter(Mandatory = $false)]
        [switch]$Detach  = $false,

        [Parameter(Mandatory = $false)]
        [switch]$Interactive  = $false,

        [Parameter(Mandatory = $false)]
        [switch]$Persist  = $false,

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

    if($Interactive) {
        $toolArgs.Add("-it")
    }

    if($Detach) {
        $toolArgs.Add("-d")
    }

    $toolArgs.Add("--name")
    $toolArgs.Add($ContainerName)

    if($DebugMode) {
        Write-Host ("DEBUGMODE : force setting --rm (dont persist) to container")
        $Persist = $false
    }

    if(!$Persist) {
        $toolArgs.Add("--rm")
    }

    if($Privileged) {
        $toolArgs.Add("--privileged")
    }

    #
    # Process folder mappings
    #
    foreach($mapping in $DirectoryMappings) {
        $toolArgs.Add("-v")
        $toolArgs.Add($mapping)
    }

    #
    # Add the container, and then args
    #
    $toolArgs.Add($Container)

    if($DebugMode) {
        $toolArgs.Add("bash")
    } else {
        $toolArgs.Add($ArgumentList)
    }

    #
    # Print some diagnostic output
    #
    foreach ($arg in $toolArgs) {
        Write-Host "ARG> $arg"
        $argString += $arg + " "
    }

    Write-Host "      Arguments : [$ContainerLauncher $argString]"
    if($DebugMode){
        Write-Host "DEBUGMODE: using bash instead of ${ArgumentList}"
    }
    Write-Host "   PROJECT_ROOT : [$PROJECT_ROOT]"

    Start-Process -NoNewWindow -FilePath $ContainerLauncher -Wait -ArgumentList $toolArgs.ToArray()
}



function Start-Start.CDocs.Container {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ContainerLauncher,

        [Parameter(Mandatory = $true)]
        [string]$ContainerName
    )

     Write-Host ""
     Write-Host ""
     Write-Host ""
     Write-Host "Start Container] ----------------------------------------------------------------"
     Write-Host "ContainerLauncher : $ContainerLauncher"
     Write-Host "ContainerName : $ContainerName"

    $argString = ""
    $toolArgs = New-Object System.Collections.Generic.List[string]

    #
    # Build 'real' arguments
    #
    $toolArgs.Add("start")
    $toolArgs.Add($ContainerName)

    #
    # Print some diagnostic output
    #
    $argString = ""
    foreach ($arg in $toolArgs) {
        $argString += $arg + " "
    }

    #
    # Add the container, and then args
    #
    Write-Host "      Arguments : [$ContainerLauncher $argString]"
    Start-Process -NoNewWindow -FilePath $ContainerLauncher -Wait -ArgumentList $toolArgs.ToArray()
}


function Start-Exec.CDocs.Container {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ContainerLauncher,

        [Parameter(Mandatory = $true)]
        [string]$ContainerName,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [switch[]]$Interactive,

        [Parameter(Mandatory = $false)]
        [switch]$DebugMode
    )

     Write-Host ""
     Write-Host ""
     Write-Host ""
     Write-Host "Exec Container] ----------------------------------------------------------------"
     Write-Host "ContainerLauncher : $ContainerLauncher"
     Write-Host "ContainerName : $ContainerName"
     Write-Host "DebugMode: $DebugMode"

    $toolArgs = New-Object System.Collections.Generic.List[string]

    #
    # Build 'real' arguments
    #
    $toolArgs.Add("exec")

    if($Interactive) {
        $toolArgs.Add("-it")
    }
    $toolArgs.Add($ContainerName)

    #
    # Add the container, and then args
    #
    if($DebugMode)
    {
        $toolArgs.Add("bash")
    }
    else
    {
        $toolArgs.AddRange($ArgumentList)
    }

    # PowerShells Start-Process seems to get confused with strings that contain
    #   spaces, even though they're supplied as strings, in an array.
    #
    #   likely this is a bug in our CDocs scripts, but it could also be in
    #   Start-Process.
    #
    #   enumerate across each string, and add escape characters
    # Create a readable diagnostic string
    foreach ($arg in $toolArgs) {
        $argString += "`"" + $arg + "`""+ " "
    }

    #
    # Add the container, and then args
    #
    Write-Host "      Arguments : [$ContainerLauncher $argString]"
    Start-Process -NoNewWindow -FilePath $ContainerLauncher -Wait -ArgumentList $argString
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

function Get-CDocs.ContainerName {
    #
    # Get the ContainerName from .CDocs.config file
    #
    try {
        $PROJECT_ROOT = Get-CDocs.ProjectRoot
        $configPath = Join-Path -Path $PROJECT_ROOT -ChildPath ".CDocs.config"

        if (!(Test-Path -Path $configPath)) {
            Write-Error "Unable to locate .CDocs.config file at $configPath"
            return $null
        }

        $configContent = Get-Content -Path $configPath -Raw
        $configJson = ConvertFrom-Json -InputObject $configContent

        if ($configJson.PSObject.Properties["ContainerName"]) {
            return $configJson.ContainerName
        } else {
            Write-Error "ContainerName property not found in .CDocs.config file"
            return $null
        }
    }
    catch {
        Write-Error "Error reading .CDocs.config file: $($_.Exception.Message)"
        return $null
    }
}


Export-ModuleMember -Function *