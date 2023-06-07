#!/bin/bash

#
# Setup the conversion to fail on error
#
set -e

echo "CONVERT MARKDOWN HELPER: v1"
echo "ARGS: $@"

function help() {
    echo "-w = word"
    echo "-p = powerpoint"
    echo "-h = html"

    echo "-m = mermaid"
    echo "-e = embed resources inside the output file"
    echo "-d = debug mode (launch bash before conversion)"


    echo "-f <file> = input file"                    
    echo "-o <dir>  = output directory"
    exit 2
}

while getopts wphmed:i:f:o: options; do
        case $options in
                w) 
                    word=1                    
                    ;;
                p) 
                    powerpoint=1                
                    ;;
                h)
                    html=1
                    ;;
                m)
                    mermaid="-F mermaid-filter"
                    ;;
                e)
                    embedResources="--embed-resources --standalone"
                    ;;
                i)
                    # -i is reserved and used by our calling script - please dont reuse it here                    
                    ;;
                f)
                    inputFile=$OPTARG                    
                    echo "INPUT FILE: $inputFile"
                    ;;
                o)
                    # "Output Directory is ignored - all outputs go to /out" 
                    ;;
                    
                d) 
                    debug=1
                    ;;
                
                *)
                    help
                    ;;
        esac
done

# echo "DEBUG: $debug"
# echo "WORD: $word"
# echo "POWERPOINT: $powerpoint"
# echo "HTML: $html"
# echo "MERMAID: $mermaid"
# echo "embedResources: $embedResources"
# echo "INPUT_FILE: $inputFile"
# echo "OUTPUT_DIR: $outputDir"


if [ "1" == "$debug" ]; then
    echo "DEBUG MODE!"
    bash
fi

if [[ -z "$inputFile" ]]; then
    echo "ERROR: input file required"
    help
    exit 1
fi


if [ "1" == "$word" ]; then
    cd ~
    args="${embedResources} /src/${inputFile} ${mermaid} -o /out/${inputFile}.docx"
    echo "CONVERT WORD: ${args}"
    pandoc $args 
    exit 1
fi