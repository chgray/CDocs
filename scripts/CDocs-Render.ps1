<#
.SYNOPSIS
    This script is used for rendering CDocs.

.DESCRIPTION
    Provide a detailed description of what this script does, its parameters, and any other relevant information.

.PARAMETER Parameter1
    Description of the first parameter.

.PARAMETER Parameter2
    Description of the second parameter.

.EXAMPLE
    Example of how to use this script.

.NOTES
    Additional notes about this script.
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile = "GlobalSetup",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = $null,

    [Parameter(Mandatory = $false)]
    [switch]$ReverseRender = $false
)

function Discover-Container-Tool {

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


function Convert-Path-To-LinuxRelativePath {
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

function Temp-File {
    param (
        [Parameter(Mandatory = $true)]
        [string]$File,

        [Parameter(Mandatory = $true)]
        [string]$Op,

        [Parameter(Mandatory = $false)]
        [switch]$Linux = $false
    )

     Write-Host ""
     Write-Host ""
     Write-Host "Seeking Temp File ---------------------------------------------"
     Write-Host "         Input : $File"
     Write-Host "            Op : $Op"
     Write-Host "         Linux : $Linux"
     Write-Host "           PWD : $PWD"

    if (!(Test-Path -Path $File)) {
        #Write-Host "Created file on Start"
        $createdFileOnStart = New-Item -Path $File -ItemType file
    }

    $File_FullPath = Resolve-Path -Path $File
    Write-Host "        FInput : $File_FullPath"
    #Write-Host " File_FullPath : $File_FullPath"

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

    $MY_PROJECT_ROOT = Split-Path -Path $InputFile -Parent
    #$File_Relative = Resolve-Path -Path $File -RelativeBasePath $CDOC_ROOT -Relative

    #$TEMP_DIR = Join-Path -Path $CDOC_ROOT -ChildPath "cdocs-temp"
    $TEMP_DIR = $CDOC_ROOT

    if (!(Test-Path -Path $TEMP_DIR)) {
        #Write-Host "Creating temp directory"
        $ni = New-Item -Path $TEMP_DIR -ItemType directory
    }

    Write-Host "  MY_PROJECT_ROOT : $MY_PROJECT_ROOT"
    Write-Host "        TEMP_DIR : $TEMP_DIR"

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

    $tempFile = $tempFile + ".$Op.tmp$extension"

    # Write-Host ""
    # Write-Host ""
    # Write-Host ""

    if($Linux) {

        #$tempFile = Split-Path -Path $tempFile -Leaf
        #$tempFile = Join-Path -Path $PROJECT_ROOT -ChildPath $tempFile

        if (!(Test-Path -Path $tempFile)) {
            $ni = New-Item -Path $tempFile -ItemType file
        }

        Write-Host "      TempFile : $tempFile"
        Write-Host "      CDOC_ROOT : $CDOC_ROOT"
        $tempFile = Resolve-Path -Path $tempFile -RelativeBasePath $CDOC_ROOT -Relative


        if ($ni -ne $null) {
            $oi = Remove-Item -Path $tempFile
        }
        $tempFile = $tempFile -replace '\\', '/'
    }


    if ($createdFileOnStart) {
        $oi = Remove-Item -Path $File
    }

    Write-Host "      TempFile : $tempFile"
    $tempFile
}

function Start-Container {
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



#$ErrorActionPreference = 'Stop'

$MergeTool = "C:\\Source\\CDocs\\tools\\CDocsMarkdownCommentRender\\bin\\Debug\\net9.0\\CDocsMarkdownCommentRender.exe"
$CONTAINER="chgray123/pandoc-arm:extra"
$CONTAINER_GNUPLOT="chgray123/chgray_repro:gnuplot"
$CONTAINER="chgray123/chgray_repro:pandoc"
# $CONTAINER="ubuntu:latest"


#
# Detect if we're using podman or docker
#
$CONTAINER_TOOL= Discover-Container-Tool

if (!(Test-Path -Path $InputFile)) {
    Write-Error "Input file doesnt exist $InputFile"
    exit 1
}

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
    Write-Error "Unable to locate CDocs project root"
    exit 1
}

#
# BUGBUG: due to bugs, we need to set the working directory to the project root
#    pandoc has some quirks with relative paths and I'm yet unsure how to handle them
#
#Write-Host "Setting Working Directory to $PROJECT_ROOT"
#Set-Location -Path $PROJECT_ROOT

#$PROJECT_ROOT = Split-Path -Path $InputFile -Parent

$InputFile = Resolve-Path -Path $InputFile
$InputFileRootDir = Split-Path -Path $InputFile -Parent
$InputFileRootDir_Linux = Convert-Path-To-LinuxRelativePath -Path $InputFileRootDir -Base $PROJECT_ROOT
$DatabaseDirectory = Join-Path -Path $PROJECT_ROOT -ChildPath "orig_media"


#$InputFile_Relative = Resolve-Path -Path $InputFile -RelativeBasePath $PROJECT_ROOT -Relative
#$InputFile_Relative = $InputFile_Relative -replace '\\', '/'
$InputFile_Relative = Split-Path -Path $InputFile -Leaf

#
# Determine the destination of output file
#
$OutputFile = $InputFile -replace ".md", ".md.docx"

#$OutputFile_Linux = Convert-Path-To-LinuxRelativePath -Path $OutputFile -Base $PROJECT_ROOT
$OutputFile_Linux = Split-Path -Path $OutputFile -Leaf


#
# Cleanup maps
#
# /data must be the project root; so that the Markdown can use ../../place1/place notation, for reuse of files
$dirMap = "$PROJECT_ROOT\:/data"
$templateMap = "$PSScriptRoot\:/templates"


Write-Host "Running CDocs-Render.ps1"
Write-Host "                MergeTool : $MergeTool"
Write-Host "          Converting file : $InputFile"
Write-Host "         InputFileRootDir : $InputFileRootDir"
Write-Host "   InputFileRootDir_Linux : $InputFileRootDir_Linux"
Write-Host "             DB Directory : $DatabaseDirectory"
Write-Host "                Container : $CONTAINER"
Write-Host "        GNUPLOT Container : $CONTAINER_GNUPLOT"
Write-Host "             PROJECT_ROOT : $PROJECT_ROOT"
Write-Host "               DirMapping : $dirMap"
Write-Host "             Template Map : $templateMap "
Write-Host "               Output Dir : $outputDir"
Write-Host "          ***  Input File : $InputFile_Relative"
Write-Host "          *** Output File : $OutputFile_Relative"


if ($ReverseRender)
{
    $InputFile_Linux = Convert-Path-To-LinuxRelativePath -Path $InputFile -Base $PROJECT_ROOT

    $OutputFile_AST = Temp-File -File $OutputFile -Op "OUT_AST"
    $OutputFile_AST_Linux = Temp-File -File $OutputFile -Op "OUT_AST" -Linux

    $OutputFile_MERGED = Temp-File -File $OutputFile -Op "OUT_MERGED"
    $OutputFile_MERGED_Linux = Temp-File -File $OutputFile -Op "OUT_MERGED" -Linux

    if(!(Test-Path -Path $OutputFile)) {
        Write-Error "Input file doesnt exist $OutputFile"
        exit 1
    }

    #
    # Convert the Word document to a pandoc AST
    #
    Start-Container -WorkingDir $InputFileRootDir_Linux `
        -ContainerLauncher $CONTAINER_TOOL `
        -Container $CONTAINER `
        -DirectoryMappings @($dirMap, $templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
        -ArgumentList `
        "-i", "$OutputFile_Linux", `
        "--extract-media", ".", `
        "-t", "json", `
        "-o",$OutputFile_AST_Linux


    if (!(Test-Path -Path $OutputFile_AST)) {
        Write-Error "Output file doesnt exist $OutputFile_AST"
        exit 1
    }

    #
    # Filter the pandoc AST using our C# image tools
    #
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "Running MergeTool]  ---------------------------------------------------------------"
    Start-Process -NoNewWindow -FilePath $MergeTool -Wait -ArgumentList "-i", $OutputFile_AST,`
                                                                        "-o", $OutputFile_MERGED,`
                                                                        "-d", $DatabaseDirectory,`
                                                                        "-r"
    #
    # Rewrite the input Markdown file
    #
    Start-Container -WorkingDir $InputFileRootDir_Linux `
        -ContainerLauncher $CONTAINER_TOOL `
        -Container $CONTAINER `
        -DirectoryMappings @($dirMap, $templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
        -ArgumentList `
            "-i", $OutputFile_MERGED_Linux, `
            "-f", "json",`
            "-o",$InputFile_Relative
}
else
{
    $InputFile_Linux = Convert-Path-To-LinuxRelativePath -Path $InputFile -Base $InputFileRootDir

    $InputFile_AST = Temp-File -File $InputFile -Op "AST"
    $InputFile_AST_Linux = Temp-File -File $InputFile -Op "AST" -Linux

    $InputFile_MERGED = Temp-File -File $InputFile -Op "MERGED"
    $InputFile_MERGED_Linux = Temp-File -File $InputFile -Op "MERGED" -Linux

    Start-Container -WorkingDir $InputFileRootDir_Linux `
            -ContainerLauncher $CONTAINER_TOOL `
            -Container $CONTAINER `
            -DirectoryMappings @($dirMap, $templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
            -ArgumentList `
            "$InputFile_Linux",`
            "-t", "json", `
            "-o",$InputFile_AST_Linux

    if (!(Test-Path -Path $InputFile_AST)) {
        Write-Error "Output file doesnt exist $InputFile_AST"
        exit 1
    }

    # Filter the pandoc AST using our C# image tools
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "---------------------------------------------------------------"
    Write-Host "Running MergeTool"
    Start-Process -NoNewWindow -FilePath $MergeTool -Wait -ArgumentList "-i", $InputFile_AST,`
                                                                        "-o", $InputFile_MERGED,`
                                                                        "-d", $DatabaseDirectory


    Start-Container -WorkingDir $InputFileRootDir_Linux `
        -ContainerLauncher $CONTAINER_TOOL `
        -Container $CONTAINER `
        -DirectoryMappings @($dirMap, $templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
        -ArgumentList `
        "-i", $InputFile_MERGED_Linux, `
        "-f", "json", `
        "-o",$OutputFile_Linux, `
        "--reference-doc","/templates/numbered-sections-6x9.docx"
}

