@echo off

echo Container : https://github.com/chgray/pandoc-dockerfiles.git
echo set CONTAINER=chgray123/pandoc-arm:extra
set CONTAINER_GNUPLOT=chgray123/chgray_repro:gnuplot
set CONTAINER=chgray123/chgray_repro:pandoc
setlocal enabledelayedexpansion

if NOT EXIST .\orig_media (
    mkdir .\orig_media
)


for %%i in (*.gnuplot) do (
    echo %%i
	mkdir orig_media
    docker run --rm -it -v "%CD%:/data" %CONTAINER_GNUPLOT% -c "./%%i"
)

for %%i in (*.Image.md) do (
    echo %%i
    docker run --rm -v "%CD%:/data" minlag/mermaid-cli -i %%i -o ./orig_media/%%i.png --width 1000
)


for %%i in (*.document.md) do (

    set INPUT_MD=%%i
    set OUTPUT_DOC=%%i.docx

    echo "IN !INPUT_MD! --> !OUTPUT_DOC!"

    docker run -it --rm -v "!CD!:/data" !CONTAINER! !INPUT_MD! -o !OUTPUT_DOC!
)
