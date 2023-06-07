#!/bin/bash

#
# Setup the conversion to fail on error
#
set -e

function help() {
    echo "-i <file> = input file"                    
    echo "-o  <dir> = output directory"
    exit 2
}

while getopts wphmed:i:f:o: options; do
        case $options in                
                i)
                    inputFile=$OPTARG
                    echo "INPUTFILE: $inputFile"
                    ;;
                f)
                    echo "F MODE $OPTARG"
                    ;;
                o)
                    outputDir=$OPTARG
                    echo "OUTPUTDIR: $outputDir"
                    ;;  
        esac
done

if [[ -z "$inputFile" ]]; then
    echo "ERROR: input file required"
    help
    exit 1
fi

myDir="$(dirname $inputFile)"         # or  cd "${1%/*}"
myDir="$(readlink -f $myDir)"
myFile="$(basename $inputFile)"

# echo "MYDIR: $myDir"
# echo "MYFILE: $myFile"


args="$@ -f ./${myFile}"
echo "ARGS: ${args}"
echo "--------------------------"
podman run --rm -it --userns=keep-id -v $myDir:/src -v $outputDir:/out localhost/chgray123/chgray_repro:pandoc bash -c "/ConvertDocument.sh ${args}"
