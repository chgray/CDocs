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
    [string]$Convert = "GlobalSetup"
)

$CONTAINER="chgray123/pandoc-arm:extra"
$CONTAINER_GNUPLOT="chgray123/chgray_repro:gnuplot"
$CONTAINER="chgray123/chgray_repro:pandoc"
$MEDIA_DIR="./orig_media"
# $CONTAINER="ubuntu:latest"

if (!(Test-Path -Path $MEDIA_DIR)) {
    Write-Host "Creating media directory"
    New-Item -Path $MEDIA_DIR -ItemType directory
}

if (!(Test-Path -Path $Convert)) {
    Write-Error "Input file doesnt exist $Convert"
    exit 1
}
$Convert = Resolve-Path -Path $Convert

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

$relativePath = Resolve-Path -Path $Convert -RelativeBasePath $PROJECT_ROOT -Relative
$relativePath = $relativePath -replace '\\', '/'
$outputDoc = $relativePath -replace ".md", ".md.docx"

# Or arguments as string array:
$dirMap = "$PROJECT_ROOT\:/data"
$templateMap = "$PSScriptRoot\:/templates"


Write-Host "Running CDocs-Render.ps1"
Write-Host "     Converting file : $Convert"
Write-Host "           Container : $CONTAINER"
Write-Host "   GNUPLOT Container : $CONTAINER_GNUPLOT"
Write-Host "Found root directory : $PROJECT_ROOT"
Write-Host "          DirMapping : $dirMap"
Write-Host "        Template Map : $templateMap "
Write-Host "     ***  Input File : $relativePath"
Write-Host "    ***  Output File : $outputDoc"

Start-Process -NoNewWindow -FilePath "docker" -Wait -ArgumentList "run","-it","--rm","-v",$dirMap,"-v",$templateMap,"$CONTAINER","$relativePath","-o","$outputDoc","--reference-doc","/templates/numbered-sections-6x9.docx"
#Start-Process -NoNewWindow -FilePath "docker" -Wait -ArgumentList "run","-it","--rm","-v",$dirMap,"-v",$templateMap,"ubuntu:latest","bash"




# for %%i in (*.gnuplot) do (
#     echo %%i
# 	mkdir orig_media
#     docker run --rm -it -v "%CD%:/data" %CONTAINER_GNUPLOT% -c "./%%i"
# )

# for %%i in (*.Image.md) do (
#     echo %%i
#     docker run --rm -v "%CD%:/data" minlag/mermaid-cli -i %%i -o ./orig_media/%%i.png --width 1000
# )

# for %%i in (*.document.md) do (
#     set INPUT_MD=%%i
#     set OUTPUT_DOC=%%i.docx

#     echo "IN !CWD!!INPUT_MD! --> !OUTPUT_DOC!"

#     @REM docker run -it --rm -v "!CD!:/data" !CONTAINER! !INPUT_MD! -o !OUTPUT_DOC!
# )
