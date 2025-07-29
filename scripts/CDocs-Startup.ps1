
param (
)

Import-Module $PSScriptRoot\CDocsLib\CDocsLib.psm1

if ($env:MY_VARIABLE) {
    Write-Error "Environment variable CDOCS_FILTER cannot be set.  Please unset it."
    exit 90
}

$ErrorActionPreference = 'Break'
#
# Detect if we're using podman or docker
#
$CONTAINER_TOOL= Get-CDocs.Container.Tool
$CONTAINER="chgray123/chgray_repro:pandoc"
$CONTAINER_NAME = Get-CDocs.ContainerName

#
# Locate the CDocs project root
#
$PROJECT_ROOT = Get-CDocs.ProjectRoot

Write-Host "CONTAINER_TOOL : $CONTAINER_TOOL"
Write-Host "  PROJECT_ROOT : $PROJECT_ROOT"
Write-Host "CONTAINER_NAME : $CONTAINER_NAME"

Start-CDocs.Container -WorkingDir "/" `
    -ContainerLauncher $CONTAINER_TOOL `
    -Container $CONTAINER `
    -DirectoryMappings @( "C:\\Source\\cdocs:/cdocs") `
    -Persist `
    -Privileged `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "bash -c /cdocs/scripts/_CDocs-Startup.sh"
