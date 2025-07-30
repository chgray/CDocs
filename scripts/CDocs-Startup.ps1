
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
$CDOCS_TOOLS_ROOT = (Resolve-Path "$PSScriptRoot/..").Path


# Build directory mappings array - include Docker socket on Mac
$DirectoryMappings = @("${CDOCS_TOOLS_ROOT}:/cdocs")
$DirectoryMappings += "/var/run/docker.sock:/var/run/docker.sock"

Write-Host "   CONTAINER_TOOL : $CONTAINER_TOOL"
Write-Host "     PROJECT_ROOT : $PROJECT_ROOT"
Write-Host "   CONTAINER_NAME : $CONTAINER_NAME"
Write-Host " CDOCS_TOOLS_ROOT : $CDOCS_TOOLS_ROOT"


# Start-CDocs.Container -WorkingDir "/" `
#     -ContainerLauncher $CONTAINER_TOOL `
#     -Container $CONTAINER `
#     -DirectoryMappings $DirectoryMappings `
#     -Persist `
#     -Privileged `
#     -Detach `
#     -ContainerName $CONTAINER_NAME `
#     -ArgumentList "sleep infinity"


#Start-Exec.CDocs.Container `
#    -ContainerLauncher $CONTAINER_TOOL `
#    -ContainerName $CONTAINER_NAME `
#    -ArgumentList "bash -c /cdocs/scripts/_CDocs-Startup.sh"

#Start-Exec.CDocs.Container `
#    -ContainerLauncher $CONTAINER_TOOL `
#    -ContainerName $CONTAINER_NAME `
#    -ArgumentList "bash", "-c", "echo export CDOCS_TOOLS_ROOT=$CDOCS_TOOLS_ROOT > /myEnv"


Start-Exec.CDocs.Container `
    -ContainerLauncher $CONTAINER_TOOL `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "bash", "-c", "echo export CDOCS_TOOLS_ROOT=$CDOCS_TOOLS_ROOT > /CDocs.env"

#    -ArgumentList "bash", "-c", "ls -l /"
