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
    try {
        $process = Start-Process -NoNewWindow -FilePath "docker" -ArgumentList "-v", -Wait -ErrorAction SilentlyContinue -PassThru

        if ($process.ExitCode -ne 0) {
            throw "docker failed with exit code $($process.ExitCode)"
        }
        $ret="docker"
    } catch {
    } finally {
    }

    if ($CONTAINER_TOOL -eq $null) {
        try {
            $process = Start-Process -NoNewWindow -FilePath "podman" -ArgumentList "-v" -Wait -ErrorAction SilentlyContinue -PassThru

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
        Write-Host "Created file on Start"
        $createdFileOnStart = New-Item -Path $File -ItemType file
    }

    $File_FullPath = Resolve-Path -Path $File
    Write-Host " File_FullPath : $File_FullPath"

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

    Write-Host "     CDOC_ROOT : $CDOC_ROOT"

    # $PROJECT_ROOT = Split-Path -Path $InputFile -Parent
    $File_Relative = Resolve-Path -Path $File -RelativeBasePath $CDOC_ROOT -Relative

    $TEMP_DIR = Join-Path -Path $CDOC_ROOT -ChildPath "cdocs-temp"

    if (!(Test-Path -Path $TEMP_DIR)) {
        Write-Host "Creating temp directory"
        $ni = New-Item -Path $TEMP_DIR -ItemType directory
    }

    #Write-Host "  PROJECT_ROOT : $PROJECT_ROOT"
    Write-Host "      TEMP_DIR : $TEMP_DIR"

    #
    # Create temp file name
    #
    $fileName = Split-Path -Path $File -Leaf
    $tempFile = Join-Path -Path $TEMP_DIR -ChildPath $fileName
    $tempFile = $tempFile + ".$Op.tmp"

    Write-Host "      TempFile : $tempFile"
    Write-Host ""
    Write-Host ""
    Write-Host ""

    if($Linux) {

        if (!(Test-Path -Path $tempFile)) {
            $ni = New-Item -Path $tempFile -ItemType file
        }

        $tempFile = Resolve-Path -Path $tempFile -RelativeBasePath $CDOC_ROOT -Relative

        if ($ni -ne $null) {
            $oi = Remove-Item -Path $tempFile
        }
        $tempFile = $tempFile -replace '\\', '/'
    }


    if ($createdFileOnStart) {
        $oi = Remove-Item -Path $File
    }

    $tempFile
}

function Start-Container {
    param (
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
$MEDIA_DIR="./orig_media"
# $CONTAINER="ubuntu:latest"


#
# Detect if we're using podman or docker
#
$CONTAINER_TOOL= Discover-Container-Tool


if (!(Test-Path -Path $MEDIA_DIR)) {
    Write-Host "Creating media directory"
    New-Item -Path $MEDIA_DIR -ItemType directory
}

if (!(Test-Path -Path $InputFile)) {
    Write-Error "Input file doesnt exist $InputFile"
    exit 1
}

$InputFile = Resolve-Path -Path $InputFile
$InputFileRootDir = Split-Path -Path $InputFile -Parent
$DatabaseDirectory = Join-Path -Path $InputFileRootDir -ChildPath "orig_media"

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
#$PROJECT_ROOT = Split-Path -Path $InputFile -Parent

$InputFile_Relative = Resolve-Path -Path $InputFile -RelativeBasePath $PROJECT_ROOT -Relative
$InputFile_Relative = $InputFile_Relative -replace '\\', '/'

#
# Determine the destination of output file
#
Write-Host "OutputDir is set to [$OutputDir]"
if (![string]::IsNullOrEmpty($OutputDir)) {
    exit 2
    # if (!(Test-Path -Path $OutputDir)) {
    #     Write-Host "Creating output directory"
    #     New-Item -Path $OutputDir -ItemType directory
    # }

    # $outputDir = Resolve-Path -Path $OutputDir -RelativeBasePath $PROJECT_ROOT -Relative
    # $OutputFile_Relative = Split-Path -Path $InputFile -Leaf
    # $OutputFile_Relative = Join-Path -Path $OutputDir -ChildPath $OutputFile_Relative
    # $OutputFile_Relative = $OutputFile_Relative -replace ".md", ".md.docx"
    # $OutputFile_Relative = $OutputFile_Relative -replace '\\', '/'
} else {
    $OutputFile_Relative = $InputFile_Relative -replace ".md", ".md.docx"
}
#
# Cleanup maps
#
# /data must be the project root; so that the Markdown can use ../../place1/place notation, for reuse of files
$dirMap = "$PROJECT_ROOT\:/data"
$templateMap = "$PSScriptRoot\:/templates"


Write-Host "Running CDocs-Render.ps1"
Write-Host "                MergeTool : $MergeTool"
Write-Host "          Converting file : $InputFile"
Write-Host " InputFileRootDir : $InputFileRootDir"
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
    $originalAST_relative=$OutputFile_Relative+".rr_ast.json"
    $originalAST=Join-Path -Path $PROJECT_ROOT -ChildPath $OutputFile_Relative".rr_ast.json"
    $transformedAST=Join-Path -Path $PROJECT_ROOT -ChildPath $OutputFile_Relative".rr_ast.rewrite.json"

    Write-Host "              OriginalAST : $originalAST"
    Write-Host "         ImageCompleteAST : $imageCompletedAST"

    #
    # Convert the Word document to a pandoc AST
    #

    if ((Test-Path -Path $originalAST)) {
        Write-Error "Output file cannot exist $originalAST"
        exit 1
    }

    Start-Container -ContainerLauncher $CONTAINER_TOOL `
        -Container $CONTAINER `
        -DirectoryMappings @($dirMap, $templateMap) `
        -ArgumentList `
        "-i", "$OutputFile_Relative", `
        "--extract-media", ".", `
        "-t", "json", `
        "-o",$originalAST_relative


    if (!(Test-Path -Path $originalAST)) {
        Write-Error "Output file doesnt exist $originalAST"
        exit 1
    }
    #
    # Filter the pandoc AST using our C# image tools
    #
    Start-Process -NoNewWindow -FilePath $MergeTool -Wait -ArgumentList "-i", $originalAST,`
                                                                        "-o", $transformedAST,`
                                                                        "-d", $DatabaseDirectory,`
                                                                        "-r"

    $transformedAST_relative = Resolve-Path -Path $transformedAST -RelativeBasePath $PROJECT_ROOT -Relative
    $transformedAST_relative = $transformedAST_relative -replace '\\', '/'

    Write-Host "           TransformedAST : $transformedAST"
    Write-Host "        TransformedAST_Rel : $transformedAST_relative"

    #
    # Rewrite the input Markdown file
    #
    Start-Container -ContainerLauncher $CONTAINER_TOOL `
        -Container $CONTAINER `
        -DirectoryMappings @($dirMap, $templateMap) `
        -ArgumentList `
            "-i", $transformedAST_relative, `
            "-f", "json",`
            "-o",$InputFile_Relative
}
else
{
    $InputFile_Linux = Convert-Path-To-LinuxRelativePath -Path $InputFile -Base $PROJECT_ROOT

    $InputFile_AST = Temp-File -File $InputFile -Op "AST"
    $InputFile_AST_Linux = Temp-File -File $InputFile -Op "AST" -Linux

    $InputFile_MERGED = Temp-File -File $InputFile -Op "MERGED"
    $InputFile_MERGED_Linux = Temp-File -File $InputFile -Op "MERGED" -Linux


    Start-Container -ContainerLauncher $CONTAINER_TOOL `
            -Container $CONTAINER `
            -DirectoryMappings @($dirMap, $templateMap) `
            -ArgumentList `
            "$InputFile_Linux",`
            "-t", "json", `
            "-o",$InputFile_AST_Linux

    if (!(Test-Path -Path $InputFile_AST)) {
        Write-Error "Output file doesnt exist $InputFile_AST"
        exit 1
    }

    # Filter the pandoc AST using our C# image tools
    Start-Process -NoNewWindow -FilePath $MergeTool -Wait -ArgumentList "-i", $InputFile_AST,`
                                                                        "-o", $InputFile_MERGED,`
                                                                        "-d", $DatabaseDirectory
    Start-Container -ContainerLauncher $CONTAINER_TOOL `
        -Container $CONTAINER `
        -DirectoryMappings @($dirMap, $templateMap) `
        -ArgumentList `
        "-i", $InputFile_MERGED_Linux, `
        "-f", "json", `
        "-o",$OutputFile_Relative, `
        "--reference-doc","/templates/numbered-sections-6x9.docx"
}

