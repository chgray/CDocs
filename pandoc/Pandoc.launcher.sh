#!/bin/sh

echo "Pandoc Launcher!"
echo "----------------------------------------------"
echo Looking for /cdocs/Pandoc.launcher.sh as an override


if [ -f "/cdocs/Pandoc.launcher.sh" ]; then
    echo "Found /cdocs/Pandoc.launcher.sh"
    cd /cdocs
    ls -l

    chmod +x ./Pandoc.launcher.sh
    dos2unix ./Pandoc.launcher.sh
    ./Pandoc.launcher.sh "$@"
else
    cd /data
    pandoc $@
    pandoc_ret=$?

    if [ $pandoc_ret -ne 0 ]; then
        echo "PANDOC FAILED: when called as follow. Exiting to console for debugging"
        echo "     pandoc $@"
        echo ""
        echo ""
        bash
    fi
fi

