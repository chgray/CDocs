param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile = "GlobalSetup",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = $null
)


Import-Module .\CDocsLib\CDocsLib.psm1

$CONTAINER_TOOL= Get-CDocs-Container-Tool
$CONTAINER="chgray123/chgray_repro:cdocs.mermaid"
$WORKING_DIR="/data"

Start-CDocContainer -WorkingDir $WORKING_DIR `
                    -ContainerLauncher $CONTAINER_TOOL `
                    -Container $CONTAINER `
                    ArgumentList `
                    bash

                    # -DirectoryMappings @($dirMap, $templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
                    # -ArgumentList `
                    # "-i", "$OutputFile_Linux", `
                    # "--extract-media", ".", `
                    # "-t", "json", `
                    # "-o",$OutputFile_AST_Linux
