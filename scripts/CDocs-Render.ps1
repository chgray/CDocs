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
        "YES"
        #Write-Error "$Path exists"
        #$Ret = Resolve-Path -Path $Path -RelativeBasePath $Base -Relative
        #$Ret = $Ret -replace '\\', '/'
    }
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

    $args = @()
    $args += "run"
    $args += "-it"
    $args += "--rm"

    foreach($mapping in $DirectoryMappings) {
        Write-Host "Mapping : [$mapping]"
        $args += "-v"
        $args += $mapping
    }

    if ($DebugMode) {
        Write-Information "Debugging"
        $args += "ubuntu:latest"
        $args += "bash"
    } else {
        Write-Information "Not Debugging"
        $args += $Container
        $args += $ArgumentList
    }

    $argString = ""
    foreach ($arg in $args) {
        $argString += $arg + " "
    }

    Write-Host "Arguments : [$ContainerLauncher $argString]"

    Start-Process -NoNewWindow -FilePath $ContainerLauncher -Wait -ArgumentList $args
}



$ErrorActionPreference = 'Stop'

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
# $PROJECT_ROOT = $PWD
# while (![string]::IsNullOrEmpty($PROJECT_ROOT)) {
#     $root = Join-Path -Path $PROJECT_ROOT -ChildPath ".CDocs.config"
#     if (Test-Path -Path $root) {
#         break
#     }
#     $PROJECT_ROOT = Split-Path -Path $PROJECT_ROOT -Parent
# }
# if([string]::IsNullOrEmpty($PROJECT_ROOT)) {
#     Write-Error "Unable to locate CDocs project root"
#     exit 1
# }
$PROJECT_ROOT = Split-Path -Path $InputFile -Parent

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
#$dirMap = "$PROJECT_ROOT\:/data"
$dirMap = "$DatabaseDirectory\:/data"
$templateMap = "$PSScriptRoot\:/templates"




Write-Host "Running CDocs-Render.ps1"
Write-Host "                MergeTool : $MergeTool"
Write-Host "          Converting file : $InputFile"
Write-Host " InputFileRootDir : $InputFileRootDir"
Write-Host "             DB Directory : $DatabaseDirectory"
Write-Host "                Container : $CONTAINER"
Write-Host "        GNUPLOT Container : $CONTAINER_GNUPLOT"
Write-Host "     Found root directory : $PROJECT_ROOT"
Write-Host "               DirMapping : $dirMap"
Write-Host "             Template Map : $templateMap "
Write-Host "               Output Dir : $outputDir"
Write-Host "          ***  Input File : $InputFile_Relative"
Write-Host "          *** Output File : $OutputFile_Relative"


if ($ReverseRender)
{
    $originalAST_relative=$OutputFile_Relative+".rr_ast.json"
    $originalAST=Join-Path -Path $PROJECT_ROOT -ChildPath $OutputFile_Relative".rr_ast.json"
    #$imageCompletedAST=Join-Path -Path $PROJECT_ROOT -ChildPath $OutputFile_Relative".rr_image.complete.rewrite.json"
    $transformedAST=Join-Path -Path $PROJECT_ROOT -ChildPath $OutputFile_Relative".rr_ast.rewrite.json"

    Write-Host "              OriginalAST : $originalAST"
    Write-Host "         ImageCompleteAST : $imageCompletedAST"

    # Convert the Word document to a pandoc AST
    Start-Process -NoNewWindow -FilePath $CONTAINER_TOOL -Wait -ArgumentList "run","-it","--rm",`
            "-v",$dirMap,`
            "-v",$templateMap,`
            "$CONTAINER",`
            "$OutputFile_Relative", `
            "--extract-media", ".", `
            "-t", "json", `
            "-o",$originalAST_relative

    # Filter the pandoc AST using our C# image tools
    Start-Process -NoNewWindow -FilePath $MergeTool -Wait -ArgumentList "-i", $originalAST,`
                                                                        "-o", $transformedAST,`
                                                                        "-d", $DatabaseDirectory,`
                                                                        "-r"

    $transformedAST_relative = Resolve-Path -Path $transformedAST -RelativeBasePath $PROJECT_ROOT -Relative
    $transformedAST_relative = $transformedAST_relative -replace '\\', '/'

    Write-Host "           TransformedAST : $transformedAST"
    Write-Host "        TransformedAST_Rel : $transformedAST_relative"

    Start-Process -NoNewWindow -FilePath $CONTAINER_TOOL -Wait -ArgumentList "run","-it","--rm",`
            "-v",$dirMap,`
            "-v",$templateMap,`
            "$CONTAINER",`
            $transformedAST_relative, `
            "-f", "json",`
            "-o",$InputFile_Relative,`
            "-t","markdown-grid_tables-simple_tables-multiline_tables"
}
else
{
    $orig_json = $InputFile+".docx.r.json"
    $adapted_json = $InputFile+".docx.r.adapted.json"

    $orig_json_relative = Convert-Path-To-LinuxRelativePath -Path $orig_json -Base $PROJECT_ROOT
    $adapted_json_relative = Convert-Path-To-LinuxRelativePath -Path $adapted_json -Base $PROJECT_ROOT

    Write-Host "       orig_json_relative : $orig_json_relative"
    Write-Host "    adapted_json_relative : $adapted_json_relative"

    Write-Host "\n\n\n"
    Write-Host " ---------------------------------------------------"
    Write-Host " Using pandoc to convert $InputFile_Relative -> $orig_json_relative"

    Start-Container -ContainerLauncher $CONTAINER_TOOL `
            -Container $CONTAINER `
            -DebugMode `
            -DirectoryMappings @($dirMap, $templateMap) `
            -ArgumentList `
            "$InputFile_Relative",`
            "-t", "json", `
            "-o",$orig_json_relative


    exit 1

    # Filter the pandoc AST using our C# image tools
    Start-Process -NoNewWindow -FilePath $MergeTool -Wait -ArgumentList "-i", $orig_json,`
                                                                        "-o", $adapted_json,`
                                                                        "-d", $DatabaseDirectory

    Write-Host "-----------------------------------------"
    Write-Host "Rendering $adapted_json_relative -> $OutputFile_Relative"

    Start-Process -NoNewWindow -FilePath $CONTAINER_TOOL -Wait -ArgumentList "run","-it","--rm", `
        "-v",$dirMap,`
        "-v",$templateMap,`
        "$CONTAINER",`
        $adapted_json_relative,`
        "-f", "json",
        #"-t","markdown",
        "-o",$OutputFile_Relative
    #,`
    #"--reference-doc","/templates/numbered-sections-6x9.docx"

#Start-Process -NoNewWindow -FilePath "docker" -Wait -ArgumentList "run","-it","--rm","-v",$dirMap,"-v",$templateMap,"ubuntu:latest","bash"
}

