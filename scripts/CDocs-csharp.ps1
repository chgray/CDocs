param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile = $null,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile = $null
)


function Extract-ThreeStrings {
    param (
        [string]$inputString
    )
    $inputString = $inputString -replace '\n', ''
    $pattern = '.*CSharp_Include\(([^,]+)",\s*([^,]+),\s*([^)]+)\).*'

    if ($inputString -match $pattern) {
        $string1 = $matches
        $string2 = $matches
        $string3 = $matches

        return @{
            String1 = $string1
            String2 = $string2
            String3 = $string3
        }
    } else {
        Write-Error "Input string does not match the expected pattern."
        throw "Unable to process include of $inputString"
    }
}

function Get-TextBetween {
    param (
        [string]$inputString,
        [string]$startString,
        [string]$endString
    )

    # Use regex to find the text between start and end strings
    if ($inputString -match "$startString(.*?)$endString") {
        return $matches
    } else {
        return "No match found"
    }
}

Import-Module $PSScriptRoot\CDocsLib\CDocsLib.psm1

$ErrorActionPreference = 'Break'

$InputFile = Resolve-Path -Path $InputFile
$IntermediateFile = $InputFile + ".csharp.md"
$HtmlFile = $OutputFile -replace ".png", ".html"

Write-Host ""
Write-Host ""
Write-host "CDocs-CSharp.ps1 ] ----------------------------------------------------------------------------------------"
Write-Host "             InputFile : $InputFile"
Write-Host "            OutputFile : $OutputFile"
Write-Host "     Intermediate File : $IntermediateFile"
Write-Host "             Html File : $HtmlFile"

#
#  Check for missing files;  clean temp files
#
if (!(Test-Path -Path $InputFile)) {
    Write-Error "Input file doesnt exist $InputFile"
    exit 1
}

if ((Test-Path -Path $IntermediateFile)) {
    Remove-Item -Path $IntermediateFile
}
if ((Test-Path -Path $HtmlFile)) {
    Remove-Item -Path $HtmlFile
}

$inputData = Get-Content -Path $InputFile
$regexTokens = Extract-ThreeStrings -inputString $inputData

$fileName =(($regexTokens["String1"][1] -replace '\n', '') -replace '"', '').Trim()
$startToken = (($regexTokens["String1"][2] -replace '\n', '') -replace '"', '').Trim()
$endToken = (($regexTokens["String1"][3] -replace '\n', '') -replace '"', '').Trim()

Add-Content -Path $IntermediateFile -Value "# CDocs: CSharp"
Add-Content -Path $IntermediateFile -Value $fileName
Add-Content -Path $IntermediateFile -Value $startToken
Add-Content -Path $IntermediateFile -Value $endToken

$fileData = Get-Content -Path $fileName

$fileData = (Get-TextBetween -inputString $fileData -startString $startToken -endString $endToken)[1]

Add-Content -Path $IntermediateFile -Value $fileData



# -=-=-=-=

$CONTAINER="chgray123/chgray_repro:pandoc"

#
# Detect if we're using podman or docker
#
$CONTAINER_TOOL= Get-CDocs.Container.Tool

if (!(Test-Path -Path $IntermediateFile)) {
    Write-Error "Input file doesnt exist $IntermediateFile"
    exit 1
}



#
# Locate the CDocs project root
#
$PROJECT_ROOT = Get-CDocs.ProjectRoot
$InputFileRootDir = Split-Path -Path $IntermediateFile -Parent
$InputFileRootDir_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $InputFileRootDir -Base $PROJECT_ROOT

$InputFile_Linux = Convert-Path.To.LinuxRelativePath.BUGGY -Path $IntermediateFile -Base $InputFileRootDir
$InputFile_AST = Get-Temp.File -File $IntermediateFile -Op "HTML"
$InputFile_AST_Linux = Get-Temp.File -File $IntermediateFile -Op "HTML" -Linux



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

&"c:\Program Files\wkhtmltopdf\bin\wkhtmltoimage.exe" -q $InputFile_AST $OutputFile

if (!(Test-Path -Path $OutputFile)) {
    Write-Error "ERROR: wkhtmltoimage didnt produce the expected output file {$InputFile_AST}"
    exit 1
}

Write-Host "             <SUCCESS>"
