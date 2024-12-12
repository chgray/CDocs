#!/bin/sh

echo "CDoc Launcher!"
echo "----------------------------------------------"
echo Looking for /cdocs/CDoc.Launcher.sh as an override

if [ -f "/cdocs/CDoc.Launcher.sh" ]; then
    echo "Found /cdocs/CDoc.Launcher.sh"
    cd /cdocs
    ls -l

    chmod +x ./CDoc.Launcher.sh
    dos2unix ./CDoc.Launcher.sh
    ./CDoc.Launcher.sh "$@"
else
    cd /data
    CDoc $@
    CDoc_ret=$?

    if [ $CDoc_ret -ne 0 ]; then
        echo "CDoc FAILED: when called as follow. Exiting to console for debugging"
        echo "     CDoc $@"
        echo ""
        echo ""
        bash
    fi
fi