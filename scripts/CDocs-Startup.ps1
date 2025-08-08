
<#
.SYNOPSIS
    Starts and configures a CDocs container environment for document processing.

.DESCRIPTION
    This script initializes a containerized environment for CDocs document processing.
    It detects the host container tool (docker/podman), starts a persistent container
    with proper volume mappings, and configures the environment for document generation.

.PARAMETER InnerContainerTool
    Specifies the container tool to use inside the container. Must be either "docker" or "podman".

.EXAMPLE
    .\CDocs-Startup.ps1 -InnerContainerTool docker
    Starts the CDocs container environment with Docker as the inner container tool.

.EXAMPLE
    .\CDocs-Startup.ps1 -InnerContainerTool podman
    Starts the CDocs container environment with Podman as the inner container tool.

.NOTES
    - Requires CDocsLib PowerShell module
    - Creates persistent container with privileged access
    - Maps project directory and CDocs tools into container
    - Configures environment variables for container operation
#>

param (
    # Required parameter that specifies the container tool to use inside the container
    # Must be either "docker" or "podman"
    [Parameter(Mandatory=$true)]
    [ValidateSet("docker", "podman")]
    [string]$InnerContainerTool
)

# Import required CDocs library module
Import-Module $PSScriptRoot\CDocsLib\CDocsLib.psm1

# Validate environment - ensure CDOCS_FILTER is not set
if ($env:MY_VARIABLE) {
    Write-Error "Environment variable CDOCS_FILTER cannot be set.  Please unset it."
    exit 90
}

# Configure error handling to break on errors
$ErrorActionPreference = 'Break'

# Detect host container environment and get project configuration
$PROJECT_ROOT = Get-CDocs.ProjectRoot
$CONTAINER_TOOL= Get-CDocs.Container.Tool
$CONTAINER="chgray123/chgray_repro:pandoc"
$CONTAINER_NAME = Get-CDocs.ContainerName
$CDOCS_TOOLS_ROOT = (Resolve-Path "$PSScriptRoot/..").Path -replace '\\', '/'
$CDOCS_PROJECT_ROOT_MAP = $PROJECT_ROOT + ":/data"
$CDOCS_TOOLS_MAP = $CDOCS_TOOLS_ROOT + ":/cdocs"

# Configure container volume mappings
# Build directory mappings array - include Docker socket on Mac for Docker-in-Docker capability
$DirectoryMappings = @()
$DirectoryMappings += $CDOCS_TOOLS_MAP                    # Map CDocs tools directory
$DirectoryMappings += "/var/run/docker.sock:/var/run/docker.sock"  # Enable Docker-in-Docker
$DirectoryMappings += $CDOCS_PROJECT_ROOT_MAP            # Map project data directory

# Display configuration information
Write-Host "        CONTAINER_TOOL : $CONTAINER_TOOL"
Write-Host "          PROJECT_ROOT : $PROJECT_ROOT"
Write-Host "        CONTAINER_NAME : $CONTAINER_NAME"
Write-Host "       CDOCS_TOOLS_MAP : $CDOCS_TOOLS_MAP"
Write-Host "CDOCS_PROJECT_ROOT_MAP : $CDOCS_PROJECT_ROOT_MAP"
Write-Host "   INNER_CONTAINER_TOOL : $InnerContainerTool"

# Start the main CDocs container in detached mode
Start-CDocs.Container -WorkingDir "/" `
    -ContainerLauncher $CONTAINER_TOOL `
    -Container $CONTAINER `
    -DirectoryMappings $DirectoryMappings `
    -Persist `
    -Privileged `
    -Detach `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "sleep infinity"

# Configure container environment variables
# Set up CDocs tools mount mapping
Start-Exec.CDocs.Container `
    -ContainerLauncher $CONTAINER_TOOL `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "bash", "-c", "echo export CDOCS_TOOLS_MOUNT_MAP=$CDOCS_TOOLS_MAP > /CDocs.env"

# Set up CDocs data mount mapping
Start-Exec.CDocs.Container `
    -ContainerLauncher $CONTAINER_TOOL `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "bash", "-c", "echo export CDOCS_DATA_MOUNT_MAP=$CDOCS_PROJECT_ROOT_MAP >> /CDocs.env"

# Configure the inner container tool based on user parameter
Start-Exec.CDocs.Container `
    -ContainerLauncher $CONTAINER_TOOL `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "bash", "-c", "echo export CDOCS_PROJECT_INNER_CONTAINER_TOOL=$InnerContainerTool >> /CDocs.env"

# Execute the container startup script to complete initialization
Start-Exec.CDocs.Container `
    -ContainerLauncher $CONTAINER_TOOL `
    -ContainerName $CONTAINER_NAME `
    -ArgumentList "bash", "-c", "/cdocs/scripts/_CDocs-Startup.sh $InnerContainerTool"