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
param (
    [Parameter(Mandatory = $true)]
    [string]$Convert = "GlobalSetup",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = $null,

    [Parameter(Mandatory = $false)]
    [switch]$ReverseRender = $false
)

$CONTAINER="chgray123/pandoc-arm:extra"
$CONTAINER_GNUPLOT="chgray123/chgray_repro:gnuplot"
$CONTAINER="chgray123/chgray_repro:pandoc"
$MEDIA_DIR="./orig_media"
# $CONTAINER="ubuntu:latest"

if (!(Test-Path -Path $MEDIA_DIR)) {
    Write-Host "Creating media directory"
    New-Item -Path $MEDIA_DIR -ItemType directory
}

if (!(Test-Path -Path $Convert)) {
    Write-Error "Input file doesnt exist $Convert"
    exit 1
}
$Convert = Resolve-Path -Path $Convert

#
# Locate the CDocs project root
#
$PROJECT_ROOT = $PWD
while ($True) {
    $root = Join-Path -Path $PROJECT_ROOT -ChildPath ".CDocs.config"
    if (Test-Path -Path $root) {
        break
    }
    $PROJECT_ROOT = Split-Path -Path $PROJECT_ROOT -Parent
}


$relativePath = Resolve-Path -Path $Convert -RelativeBasePath $PROJECT_ROOT -Relative
$relativePath = $relativePath -replace '\\', '/'

#
# Determine the destination of output file
#
Write-Host "OutputDir is set to [$OutputDir]"
if (![string]::IsNullOrEmpty($OutputDir)) {

    if (!(Test-Path -Path $OutputDir)) {
        Write-Host "Creating output directory"
        New-Item -Path $OutputDir -ItemType directory
    }

    $outputDir = Resolve-Path -Path $OutputDir -RelativeBasePath $PROJECT_ROOT -Relative
    $outputDoc_relative = Split-Path -Path $Convert -Leaf
    $outputDoc_relative = Join-Path -Path $OutputDir -ChildPath $outputDoc_relative
    $outputDoc_relative = $outputDoc_relative -replace ".md", ".md.docx"
    $outputDoc_relative = $outputDoc_relative -replace '\\', '/'
} else {
    $outputDoc_relative = $relativePath -replace ".md", ".md.docx"
}
#
# Cleanup maps
#
$dirMap = "$PROJECT_ROOT\:/data"
$templateMap = "$PSScriptRoot\:/templates"



#
# Detect if we're using podman or docker
#
$CONTAINER_TOOL=$null
try {
    $process = Start-Process -NoNewWindow -FilePath "docker" -ArgumentList "-v", -Wait -ErrorAction SilentlyContinue -PassThru

    if ($process.ExitCode -ne 0) {
        throw "docker failed with exit code $($process.ExitCode)"
    }
    $CONTAINER_TOOL="docker"
} catch {
} finally {
}

if ($CONTAINER_TOOL -eq $null) {
    try {
        $process = Start-Process -NoNewWindow -FilePath "podman" -ArgumentList "-v" -Wait -ErrorAction SilentlyContinue -PassThru

        if ($process.ExitCode -ne 0) {
            throw "podman failed with exit code $($process.ExitCode)"
        }
        $CONTAINER_TOOL="podman"
    } catch {
    } finally {
    }
}



Write-Host "Running CDocs-Render.ps1"
Write-Host "     Converting file : $Convert"
Write-Host "           Container : $CONTAINER"
Write-Host "   GNUPLOT Container : $CONTAINER_GNUPLOT"
Write-Host "Found root directory : $PROJECT_ROOT"
Write-Host "          DirMapping : $dirMap"
Write-Host "        Template Map : $templateMap "
Write-Host "          Output Dir : $outputDir"
Write-Host "     ***  Input File : $relativePath"
Write-Host "     *** Output File : $outputDoc_relative"


if ($ReverseRender)
{
    Write-Host "1. Reverse Mode"

    $originalAST_relative=$outputDoc_relative+"_ast.json"
    $originalAST=Join-Path -Path $PROJECT_ROOT -ChildPath $outputDoc_relative"_ast.json"
    $transformedAST=Join-Path -Path $PROJECT_ROOT -ChildPath $outputDoc_relative"_ast.rewrite.json"

    $MergeTool = "c:\\Source\\CDocs\\tools\\pandocImageMerge\\bin\\Debug\\net8.0\\pandocImageMerge.exe"

    Write-Host "         OriginalAST : $originalAST"

    Write-Host "2. Converting $relativePath to AST named $originalAST_relative"

    # Convert the Word document to a pandoc AST
    Start-Process -NoNewWindow -FilePath $CONTAINER_TOOL -Wait -ArgumentList "run","-it","--rm",`
            "-v",$dirMap,`
            "-v",$templateMap,`
            "$CONTAINER",`
            "$outputDoc_relative", `
            "--extract-media", ".", `
            "-t", "json", `
            "-o",$originalAST_relative

    # Filter the pandoc AST using our C# image tools
    Start-Process -NoNewWindow -FilePath $MergeTool -Wait -ArgumentList "-i", $originalAST, "-o", $transformedAST,"-r","./orig_media"

    $transformedAST_relative = Resolve-Path -Path $transformedAST -RelativeBasePath $PROJECT_ROOT -Relative
    $transformedAST_relative = $transformedAST_relative -replace '\\', '/'

    Write-Host "      TransformedAST : $transformedAST"
    Write-Host "  TransformedAST_Rel : $transformedAST_relative"


    Write-Host "4. Converting $originalAST_relative back to markdown as $relativePath"

    # Convert back to Markdown
    Start-Process -NoNewWindow -FilePath $CONTAINER_TOOL -Wait -ArgumentList "run","-it","--rm",`
            "-v",$dirMap,`
            "-v",$templateMap,`
            "$CONTAINER",`
            $transformedAST_relative, `
            "-f", "json", `
            "-o",$relativePath,`
            "-t","markdown-grid_tables-simple_tables-multiline_tables"

    #docker run -it --rm -v "!CD!:/data" !CONTAINER! !OUTPUT_DOC! --extract-media . -t json -o !OUTPUT_DOC!_ast.json

    #c:\Source\CDocs\tools\pandocImageMerge\bin\Debug\net8.0\pandocImageMerge.exe -i !OUTPUT_DOC!_ast.json -o !OUTPUT_DOC!_ast.rewrite.json -r ./orig_media

    #docker run -it --rm -v "!CD!:/data" !CONTAINER! !OUTPUT_DOC!_ast.rewrite.json -f json -o !INPUT_MD! -t markdown-grid_tables-simple_tables-multiline_tables

}
else
{
Start-Process -NoNewWindow -FilePath $CONTAINER_TOOL -Wait -ArgumentList "run","-it","--rm","-v",$dirMap,"-v",$templateMap,"$CONTAINER","$relativePath","-o",$outputDoc_relative,"--reference-doc","/templates/numbered-sections-6x9.docx"
#Start-Process -NoNewWindow -FilePath "docker" -Wait -ArgumentList "run","-it","--rm","-v",$dirMap,"-v",$templateMap,"ubuntu:latest","bash"
}



# for %%i in (*.gnuplot) do (
#     echo %%i
# 	mkdir orig_media
#     docker run --rm -it -v "%CD%:/data" %CONTAINER_GNUPLOT% -c "./%%i"
# )

# for %%i in (*.Image.md) do (
#     echo %%i
#     docker run --rm -v "%CD%:/data" minlag/mermaid-cli -i %%i -o ./orig_media/%%i.png --width 1000
# )

# for %%i in (*.document.md) do (
#     set INPUT_MD=%%i
#     set OUTPUT_DOC=%%i.docx

#     echo "IN !CWD!!INPUT_MD! --> !OUTPUT_DOC!"

#     @REM docker run -it --rm -v "!CD!:/data" !CONTAINER! !INPUT_MD! -o !OUTPUT_DOC!
# )
