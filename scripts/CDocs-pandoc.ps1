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

$toolArgs = New-Object System.Collections.Generic.List[string]

foreach ($arg in $args) {
    Write-Output "Argument: $arg"
    $toolArgs.Add($arg)
}

Import-Module $PSScriptRoot\CDocsLib\CDocsLib.psm1

$ErrorActionPreference = 'Break'
#$ErrorActionPreference = 'Stop'

$CONTAINER="chgray123/chgray_repro:pandoc"

#
# Cleanup maps
#
$templateMap = "$PSScriptRoot\:/templates"

#
# Detect if we're using podman or docker
#
$CONTAINER_TOOL= Get-CDocs.Container.Tool
$PROJECT_ROOT=  Get-CDocs.ProjectRoot

$root_dir = Convert-LocalPath.To.CDocContainerPath -Path $PWD.Path -Base $PROJECT_ROOT

Start-CDocs.Container -WorkingDir $root_dir `
        -ContainerLauncher $CONTAINER_TOOL `
        -Container $CONTAINER `
        -DirectoryMappings @($templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
        -ArgumentList $toolArgs.ToArray()
