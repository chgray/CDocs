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
    [string]$FileA,

    [Parameter(Mandatory = $true)]
    [string]$FileB
)

$CONTAINER="chgray123/pandoc-arm:extra"
$CONTAINER_GNUPLOT="chgray123/chgray_repro:gnuplot"
$CONTAINER="chgray123/chgray_repro:pandoc"
$MEDIA_DIR="./orig_media"
# $CONTAINER="ubuntu:latest"

if (!(Test-Path -Path $FileA)) {
    Write-Host "Invalid FileA=$FileA"
    exit 1
}

if (!(Test-Path -Path $FileB)) {
    Write-Host "Invalid FileB=$FileB"
    exit 2
}

$FileA = Resolve-Path -Path $FileA
$FileB = Resolve-Path -Path $FileB

#
# Locate the CDocs project root
#
$PROJECT_ROOT = $PWD
while ($True) {
    $root = Join-Path -Path $PROJECT_ROOT -ChildPath ".CDocs.config"
    if (Test-Path -Path $root) {
        break
    }
    $PROJECT_ROOT = Split-Path -Path $PROJECT_ROOT -Parent
}


$FileA = Resolve-Path -Path $FileA -RelativeBasePath $PROJECT_ROOT -Relative
$FileB = Resolve-Path -Path $FileB -RelativeBasePath $PROJECT_ROOT -Relative

$FileA = $FileA -replace '\\', '/'
$FileB = $FileB -replace '\\', '/'

# Or arguments as string array:
$dirMap = "$PROJECT_ROOT\:/data"
$templateMap = "$PSScriptRoot\:/templates"


Write-Host "Running CDocs-Combine.ps1"
Write-Host "               FileA : $FileA"
Write-Host "               FileB : $FileB"

Start-Process -NoNewWindow -FilePath "docker" -Wait -ArgumentList "run","-it","--rm","-v",$dirMap,"-v",$templateMap,"$CONTAINER", $FileB, $FileA,"-o", $FileB, "--reference-doc","/templates/numbered-sections-6x9.docx"
#Start-Process -NoNewWindow -FilePath "docker" -Wait -ArgumentList "run","-it","--rm","-v",$dirMap,"-v",$templateMap,"ubuntu:latest","bash"

