
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
$PROJECT_ROOT = Get-CDocs.ProjectRoot
$CONTAINER_TOOL= Get-CDocs.Container.Tool
$CONTAINER="chgray123/chgray_repro:pandoc"
$CONTAINER_NAME = Get-CDocs.ContainerName
$CDOCS_TOOLS_ROOT = (Resolve-Path "$PSScriptRoot/..").Path -replace '\\', '/'
$CDOCS_PROJECT_ROOT_MAP = $PROJECT_ROOT + ":/data"
$CDOCS_TOOLS_MAP = $CDOCS_TOOLS_ROOT + ":/cdocs"

# Build directory mappings array - include Docker socket on Mac
$DirectoryMappings = @() #"${CDOCS_TOOLS_ROOT}:/cdocs")
$DirectoryMappings += $CDOCS_TOOLS_MAP
$DirectoryMappings += "/var/run/docker.sock:/var/run/docker.sock"
$DirectoryMappings += $CDOCS_PROJECT_ROOT_MAP

Write-Host "        CONTAINER_TOOL : $CONTAINER_TOOL"
Write-Host "          PROJECT_ROOT : $PROJECT_ROOT"
Write-Host "        CONTAINER_NAME : $CONTAINER_NAME"
Write-Host "       CDOCS_TOOLS_MAP : $CDOCS_TOOLS_MAP"
Write-Host "CDOCS_PROJECT_ROOT_MAP : $CDOCS_PROJECT_ROOT_MAP"


# Start-CDocs.Container -WorkingDir "/" `
#     -ContainerLauncher $CONTAINER_TOOL `
#     -Container $CONTAINER `
#     -DirectoryMappings $DirectoryMappings `
#     -Persist `
#     -Privileged `
#     -Detach `
#     -ContainerName $CONTAINER_NAME `
#     -ArgumentList "sleep infinity"

Start-Exec.CDocs.Container `
    -ContainerLauncher $CONTAINER_TOOL `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "bash", "-c", "echo export CDOCS_TOOLS_MOUNT_MAP=$CDOCS_TOOLS_MAP > /CDocs.env"

Start-Exec.CDocs.Container `
    -ContainerLauncher $CONTAINER_TOOL `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "bash", "-c", "echo export CDOCS_DATA_MOUNT_MAP=$CDOCS_PROJECT_ROOT_MAP >> /CDocs.env"

Start-Exec.CDocs.Container `
    -ContainerLauncher $CONTAINER_TOOL `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "bash", "-c", "echo export CDOCS_PROJECT_INNER_CONTAINER_TOOL=docker >> /CDocs.env"

Start-Exec.CDocs.Container `
    -ContainerLauncher $CONTAINER_TOOL `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "bash", "-c", "/cdocs/scripts/_CDocs-Startup.sh"