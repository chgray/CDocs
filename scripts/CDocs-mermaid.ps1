param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile = "GlobalSetup",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = $null
)

Import-Module .\CDocsLib\CDocsLib.psm1

$InputFile = Resolve-Path -Path $InputFile

if (!(Test-Path -Path $InputFile)) {
    Write-Error "Input file doesnt exist $InputFile"
    exit 1
}


$CONTAINER_TOOL = Get-CDocs.Container.Tool
$CONTAINER="chgray123/chgray_repro:cdocs.mermaid"
$PROJECT_ROOT=  Get-CDocs.ProjectRoot
$InputFileRootDir = Split-Path -Path $InputFile -Parent
$WORKING_DIR = Convert-LocalPath.To.CDocContainerPath -Path $InputFileRootDir -Base $PROJECT_ROOT
$JUST_FILENAME = Split-Path -Path $InputFile -Leaf

Write-Host "       INPUT_FILE : $InputFile"
Write-Host "  INPUT_FILE_ROOT : $InputFileRootDir"
Write-Host "     PROJECT_ROOT : $PROJECT_ROOT"
Write-Host "   CONTAINER_TOOL : $CONTAINER_TOOL"
Write-Host "      WORKING_DIR : $WORKING_DIR"
Write-Host "        CONTAINER : $CONTAINER"
Write-Host "       OUTPUT_DIR : $OutputDir"

Start-CDocs.Container -WorkingDir $WORKING_DIR `
                    -ContainerLauncher $CONTAINER_TOOL `
                    -DirectoryMappings @("C:\\Source\\CDocs\\pandoc:/cdocs") `
                    -Container $CONTAINER `
                    -ArgumentList `
                    "/home/mermaidcli/node_modules/.bin/mmdc -p /puppeteer-config.json"
                    "-i", $JUST_FILENAME,
                    "-o", "yack.png",
                    "--width", "1000"

                    #"-i", "/data/$InputFile.mermaid", `
                    #
                    #-i ./graph.mermaid -o ./foo.png --width 100

                    # -DirectoryMappings @($dirMap, $templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
                    # -ArgumentList `
                    # "-i", "$OutputFile_Linux", `
                    # "--extract-media", ".", `
                    # "-t", "json", `
                    # "-o",$OutputFile_AST_Linux
