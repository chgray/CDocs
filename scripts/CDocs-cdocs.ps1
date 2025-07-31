param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile = $null,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile = $null
)

Import-Module $PSScriptRoot\CDocsLib\CDocsLib.psm1

$InputFile = Resolve-Path -Path $InputFile

if (!(Test-Path -Path $InputFile)) {
    Write-Error "Input file doesnt exist $InputFile"
    exit 1
}

Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "```cdocs discovered and being processed ] -------------------------------------------------------------------"
Write-Host "        INPUT_FILE : $InputFile"
Write-Host "       OUTPUT_FILE : $OutputFile"
Write-Host ""
Write-Host ""

Rename-Item -Path $InputFile -NewName $InputFile+".html"

&"c:\Program Files\wkhtmltopdf\bin\wkhtmltoimage.exe" $InputFile+".html" $OutputFile

Rename-Item -NewName $InputFile -Path $InputFile+".html"
