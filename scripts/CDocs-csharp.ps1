param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile = $null,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile = $null
)

Import-Module $PSScriptRoot\CDocsLib\CDocsLib.psm1

$ErrorActionPreference = 'Break'

$InputFile = Resolve-Path -Path $InputFile

if (!(Test-Path -Path $InputFile)) {
    Write-Error "Input file doesnt exist $InputFile"
    exit 1
}

Write-Host "Adding Stuff to place"
$InputFile = $InputFile + ".csharp"
Add-Content -Path $InputFile -Value "# CDocs: CSharp"
Add-Content -Path $InputFile -Value "printf"


Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "```csharp discovered and being processed ] -------------------------------------------------------------------"
Write-Host "        INPUT_FILE : $InputFile"
Write-Host "       OUTPUT_FILE : $OutputFile"
Write-Host ""
Write-Host ""

$HtmlFile = $OutputFile -replace ".png", ".html"


# -=-=-=-=

$CONTAINER="chgray123/chgray_repro:pandoc"

#
# Detect if we're using podman or docker
#
$CONTAINER_TOOL= Get-CDocs.Container.Tool

if (!(Test-Path -Path $InputFile)) {
    Write-Error "Input file doesnt exist $InputFile"
    exit 1
}



#
# Locate the CDocs project root
#
$PROJECT_ROOT = Get-CDocs.ProjectRoot
$InputFileRootDir = Split-Path -Path $InputFile -Parent
$InputFileRootDir_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $InputFileRootDir -Base $PROJECT_ROOT

$InputFile_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $InputFile -Base $InputFileRootDir
$InputFile_AST = Get-Temp.File -File $InputFile -Op "HTML"
$InputFile_AST_Linux = Get-Temp.File -File $InputFile -Op "HTML" -Linux

#$InputFile_MERGED = Get-Temp.File -File $InputFile -Op "MERGED"
#$InputFile_MERGED_Linux = Get-Temp.File -File $InputFile -Op "MERGED" -Linux

#
# Cleanup maps
#
$templateMap = "$PSScriptRoot\:/templates"

Start-CDocs.Container -WorkingDir $InputFileRootDir_Linux `
        -ContainerLauncher $CONTAINER_TOOL `
        -Container $CONTAINER `
        -DirectoryMappings @($templateMap, "C:\\Source\\DynamicTelemetry\\cdocs:/cdocs") `
        -ArgumentList `
        "$InputFile_Linux",`
        "-t", "html", `
        "-o",$InputFile_AST_Linux

if (!(Test-Path -Path $InputFile_AST)) {
    Write-Error "ERROR: Container didnt produce the expected output file {$InputFile_AST}"
    exit 1
}

# -=-=-=-=
type $InputFile_AST

Write-Host "HTMLFile: $InputFile_AST"
Write-Host "OutputFile: $OutputFile"

&"c:\Program Files\wkhtmltopdf\bin\wkhtmltoimage.exe" $InputFile_AST $OutputFile

