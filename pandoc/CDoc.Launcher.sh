#!/bin/bash

echo "CDoc Launcher! [ $@]"
echo "----------------------------------------------"
echo Looking for /cdocs/CDoc.Launcher.sh as an override


#
# If we 'see' /cdocs/CDoc.Launcher.sh and if it's the first time we're called
#     then permit recursion, otherwise stop the loop
#
if [ -f "/cdocs/CDoc.Launcher.sh" ]; then
    CDOC_RECURSE=1
fi

if [[ ! -z "${CDOC_FIRST_CALL}" ]]; then
    unset CDOC_FIRST_CALL
else
    unset CDOC_RECURSE
fi

if [[ ! -z "${CDOC_RECURSE}" ]]; then
    echo "Found /cdocs/CDoc.Launcher.sh"
    cd /cdocs
    chmod +x ./CDoc.Launcher.sh
    dos2unix ./CDoc.Launcher.sh

    unset CDOC_FIRST_CALL
    ./CDoc.Launcher.sh "$@"
else
    cd /data
    echo "ARGS $@"

    cd $1
    ls
    shift

    echo "New: ARGS $@"
    tool=$1
    shift

    echo "Tool: $tool"
    echo "-----------------"
    $($tool) $@

    CDoc_ret=$?

    if [ $CDoc_ret -ne 0 ]; then
        echo "CDoc FAILED: when called as follow. Exiting to console for debugging"
        echo "     CDoc $@"
        echo ""
        echo ""
        bash
    fi
fi