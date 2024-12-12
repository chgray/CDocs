param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile = "GlobalSetup",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = $null
)


Import-Module .\CDocLib.psm1

Start-CDocContainer
