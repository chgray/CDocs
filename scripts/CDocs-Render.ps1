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

    [Parameter(Mandatory = $true)]
    [string]$OutputFile = "GlobalSetup",

    [Parameter(Mandatory = $false)]
    [switch]$ReverseRender = $false,

    [Parameter(Mandatory = $false)]
    [switch]$DebugMode = $false
)

Import-Module $PSScriptRoot\CDocsLib\CDocsLib.psm1

if ($env:MY_VARIABLE) {
    Write-Error "Environment variable CDOCS_FILTER cannot be set.  Please unset it."
    exit 90
}

$ErrorActionPreference = 'Break'
#$ErrorActionPreference = 'Stop'

#
# Detect if we're using podman or docker
#
$CONTAINER_TOOL= Get-CDocs.Container.Tool
$CONTAINER_NAME = Get-CDocs.ContainerName


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
$InputFile_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $InputFile -Base $PROJECT_ROOT
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
#$InputFile_Relative = Split-Path -Path $InputFile -Leaf

#
# Determine the destination of output file
#
# if ($EPUB) {
#     $OutputFile = $InputFile -replace ".md", ".pdf"
# } else {
#     $OutputFile = $InputFile -replace ".md", ".docx"
# }


#$OutputFile_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $OutputFile -Base $PROJECT_ROOT

#$OutputFile_Linux = Split-Path -Path $OutputFile -Leaf

$OutputFile_Linux = (New-Object -TypeName System.IO.FileInfo -ArgumentList $OutputFile).FullName
$OutputFile_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $OutputFile_Linux -Base $PROJECT_ROOT


#
# Cleanup maps
#
$templateMap = "$PSScriptRoot\:/templates"


Write-Host "Running CDocs-Render.ps1"
Write-Host "          Converting file : $InputFile"
Write-Host "         InputFileRootDir : $InputFileRootDir"
Write-Host "   InputFileRootDir_Linux : $InputFileRootDir_Linux"
Write-Host "             DB Directory : $DatabaseDirectory"
Write-Host "                Container : $CONTAINER"
Write-Host "        GNUPLOT Container : $CONTAINER_GNUPLOT"
Write-Host "             PROJECT_ROOT : $PROJECT_ROOT"
Write-Host "           CONTAINER_NAME : $CONTAINER_NAME"
Write-Host "             Template Map : $templateMap "
Write-Host "               Output Dir : $outputDir"
Write-Host "         OutputFile_Linux : $OutputFile_Linux"
Write-Host "          InputFile_Linux : $InputFile_Linux"
Write-Host "          ***  Input File : $InputFile_Relative"
Write-Host "          *** Output File : $OutputFile_Relative"


if(!(Test-Path -Path $InputFile)) {
    Write-Error "Input file doesnt exist $InputFile"
    exit 1
}

#
# Convert the Word document to a pandoc AST
#
if($ReverseRender)
{
    if($DebugMode) {
        Start-Exec.CDocs.Container -ContainerLauncher $CONTAINER_TOOL `
        -ContainerName $CONTAINER_NAME `
        -DebugMode `
        -ArgumentList "/cdocs/scripts/_CDocs-Render.sh /data/$InputFile_Linux -o /data/$OutputFile_Linux --reverse"
    } else {
        Start-Exec.CDocs.Container -ContainerLauncher $CONTAINER_TOOL `
        -ContainerName $CONTAINER_NAME `
        -ArgumentList "/cdocs/scripts/_CDocs-Render.sh /data/$InputFile_Linux -o /data/$OutputFile_Linux --reverse"
    }
}
else
{
    if($DebugMode) {
        Start-Exec.CDocs.Container -ContainerLauncher $CONTAINER_TOOL `
        -ContainerName $CONTAINER_NAME `
        -DebugMode `
        -ArgumentList "/cdocs/scripts/_CDocs-Render.sh /data/$InputFile_Linux -o /data/$OutputFile_Linux"
    } else {
        Start-Exec.CDocs.Container -ContainerLauncher $CONTAINER_TOOL `
        -ContainerName $CONTAINER_NAME `
        -ArgumentList "/cdocs/scripts/_CDocs-Render.sh /data/$InputFile_Linux -o /data/$OutputFile_Linux"
    }
}
