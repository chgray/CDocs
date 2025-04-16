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
    [switch]$ReverseRender = $false,

    [Parameter(Mandatory = $false)]
    [switch]$NormalMargins = $false,

    [Parameter(Mandatory = $false)]
    [switch]$EPUB = $false
)

Import-Module $PSScriptRoot\CDocsLib\CDocsLib.psm1

if ($env:MY_VARIABLE) {
    Write-Error "Environment variable CDOCS_FILTER cannot be set.  Please unset it."
    exit 90
}

$ErrorActionPreference = 'Break'
#$ErrorActionPreference = 'Stop'

$MergeTool = "C:\\Source\\CDocs\\tools\\CDocsMarkdownCommentRender\\bin\\Debug\\net8.0\\CDocsMarkdownCommentRender.exe"
$CONTAINER="chgray123/chgray_repro:pandoc"
# $CONTAINER="ubuntu:latest"


#
# Detect if we're using podman or docker
#
$CONTAINER_TOOL= Get-CDocs.Container.Tool

if (!(Test-Path -Path $InputFile)) {
    Write-Error "Input file doesnt exist $InputFile"
    exit 1
}

#
# Locate the CDocs project root
#
$PROJECT_ROOT = Get-CDocs.ProjectRoot



#$PROJECT_ROOT = Split-Path -Path $InputFile -Parent

$InputFile = Resolve-Path -Path $InputFile
$InputFileRootDir = Split-Path -Path $InputFile -Parent
$InputFileRootDir_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $InputFileRootDir -Base $PROJECT_ROOT
$DatabaseDirectory = Join-Path -Path $PROJECT_ROOT -ChildPath "orig_media"


#
# BUGBUG: due to bugs, we need to set the working directory to the project root
#    pandoc has some quirks with relative paths and I'm yet unsure how to handle them
#
#Write-Host "Setting Working Directory to $PROJECT_ROOT"
Set-Location -Path $InputFileRootDir

#$InputFile_Relative = Resolve-Path -Path $InputFile -RelativeBasePath $PROJECT_ROOT -Relative
#$InputFile_Relative = $InputFile_Relative -replace '\\', '/'
$InputFile_Relative = Split-Path -Path $InputFile -Leaf

#
# Determine the destination of output file
#
if ($EPUB) {
    $OutputFile = $InputFile -replace ".md", ".pdf"
} else {
    $OutputFile = $InputFile -replace ".md", ".docx"
}


#$OutputFile_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $OutputFile -Base $PROJECT_ROOT
$OutputFile_Linux = Split-Path -Path $OutputFile -Leaf


#
# Cleanup maps
#
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
Write-Host "             Template Map : $templateMap "
Write-Host "               Output Dir : $outputDir"
Write-Host "          ***  Input File : $InputFile_Relative"
Write-Host "          *** Output File : $OutputFile_Relative"


if ($ReverseRender)
{
    $InputFile_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $InputFile -Base $PROJECT_ROOT

    $OutputFile_AST = Get-Temp.File -File $OutputFile -Op "OUT_AST"
    $OutputFile_AST_Linux = Get-Temp.File -File $OutputFile -Op "OUT_AST" -Linux

    $OutputFile_MERGED = Get-Temp.File -File $OutputFile -Op "OUT_MERGED"
    $OutputFile_MERGED_Linux = Get-Temp.File -File $OutputFile -Op "OUT_MERGED" -Linux

    if(!(Test-Path -Path $OutputFile)) {
        Write-Error "Input file doesnt exist $OutputFile"
        exit 1
    }

    #
    # Convert the Word document to a pandoc AST
    #
    Start-CDocs.Container -WorkingDir $InputFileRootDir_Linux `
        -ContainerLauncher $CONTAINER_TOOL `
        -Container $CONTAINER `
        -DirectoryMappings @($templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
        -ArgumentList `
        "/cdocs/CDoc.Launcher.sh",
        $InputFileRootDir_Linux,
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
    Write-Host "Running MergeTool] ----------------------------------------------------------------------------------------"
    Start-Process -NoNewWindow -FilePath $MergeTool -Wait -ArgumentList "-i", $OutputFile_AST,`
                                                                        "-o", $OutputFile_MERGED,`
                                                                        "-r"

    #
    # Make sure we have an output file
    #
    if(!(Test-Path -Path $OutputFile_MERGED)) {
        Write-Error "Output file from merge-tool doesnt exist $OutputFile_MERGED"
        exit 1
    }

    #
    # Rewrite the input Markdown file
    #
    Start-CDocs.Container -WorkingDir $InputFileRootDir_Linux `
        -ContainerLauncher $CONTAINER_TOOL `
        -Container $CONTAINER `
        -DirectoryMappings @($templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
        -ArgumentList `
            "/cdocs/CDoc.Launcher.sh",
            $InputFileRootDir_Linux,
            "-i", $OutputFile_MERGED_Linux, `
            "-f", "json",`
            "-o",$InputFile_Relative
}
else
{
    $InputFile_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $InputFile -Base $InputFileRootDir

    $InputFile_AST = Get-Temp.File -File $InputFile -Op "AST"
    $InputFile_AST_Linux = Get-Temp.File -File $InputFile -Op "AST" -Linux

    $InputFile_MERGED = Get-Temp.File -File $InputFile -Op "MERGED"
    $InputFile_MERGED_Linux = Get-Temp.File -File $InputFile -Op "MERGED" -Linux

    Write-Host "           *** Input File : $InputFile_Linux"
    Write-Host "          *** Output File : $InputFile_AST_Linux"


    Start-CDocs.Container -WorkingDir $InputFileRootDir_Linux `
            -ContainerLauncher $CONTAINER_TOOL `
            -Container $CONTAINER `
            -DirectoryMappings @($templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
            -ArgumentList `
            "/cdocs/CDoc.Launcher.sh",
            $InputFileRootDir_Linux,
            "$InputFile_Linux",`
            "-t", "json", `
            "-o",$InputFile_AST_Linux


    if (!(Test-Path -Path $InputFile_AST)) {
        Write-Error "ERROR: Container didnt produce the expected output file {$InputFile_AST}"
        exit 1
    }

    # Filter the pandoc AST using our C# image tools
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "---------------------------------------------------------------"
    Write-Host "Running MergeToolX [$MergeTool] "
    Start-Process -NoNewWindow -FilePath $MergeTool -Wait `
                -ArgumentList  `
                "-i", $InputFile_AST,`
                "-o", $InputFile_MERGED

    if (!(Test-Path -Path $InputFile_MERGED)) {
        Write-Error "Output file doesnt exist $InputFile_MERGED"
        exit 1
    }


    if ($NormalMargins) {
        Start-CDocs.Container -WorkingDir $InputFileRootDir_Linux `
            -ContainerLauncher $CONTAINER_TOOL `
            -Container $CONTAINER `
            -DirectoryMappings @($templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
            -ArgumentList `
            "/cdocs/CDoc.Launcher.sh",
            $InputFileRootDir_Linux,
            "-i", $InputFile_MERGED_Linux, `
            "-f", "json", `
            "-o",$OutputFile_Linux, `
            "--reference-doc","/templates/numbered-sections.docx"
    } else {
        Start-CDocs.Container -WorkingDir $InputFileRootDir_Linux `
            -ContainerLauncher $CONTAINER_TOOL `
            -Container $CONTAINER `
            -DirectoryMappings @($templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
            -ArgumentList `
            "/cdocs/CDoc.Launcher.sh",
            $InputFileRootDir_Linux,
            "-i", $InputFile_MERGED_Linux, `
            "-f", "json", `
            "-o",$OutputFile_Linux, `
            "--reference-doc","/templates/numbered-sections-6x9.docx"
    }
}

