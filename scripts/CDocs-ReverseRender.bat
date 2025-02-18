@echo off


echo set CONTAINER=chgray123/pandoc-arm:extra
set CONTAINER_GNUPLOT=chgray123/chgray_repro:gnuplot
set CONTAINER=chgray123/chgray_repro:pandoc
set PANDOC_MERGE=c:\Source\CDocs\tools\pandocImageMerge\bin\Debug\net8.0\pandocImageMerge.exe
setlocal enabledelayedexpansion

echo hi

if EXIST %PANDOC_MERGE% (
    echo "GOOD"
) else (
    echo "Merge tool doesnt exist %PANDOC_MERGE%
    pause
    goto :eof
)



for %%i in (*.document.md) do (
    set INPUT_MD=%%i
    set OUTPUT_DOC=%%i.docx

    echo "IN !INPUT_MD! --> !OUTPUT_DOC!"
    docker run -it --rm -v "!CD!:/data" !CONTAINER! !OUTPUT_DOC! --extract-media . -t json -o !OUTPUT_DOC!_ast.json

    c:\Source\CDocs\tools\pandocImageMerge\bin\Debug\net8.0\pandocImageMerge.exe -i !OUTPUT_DOC!_ast.json -o !OUTPUT_DOC!_ast.rewrite.json -r ./orig_media

    docker run -it --rm -v "!CD!:/data" !CONTAINER! !OUTPUT_DOC!_ast.rewrite.json -f json -o !INPUT_MD! -t markdown-grid_tables-simple_tables-multiline_tables
)