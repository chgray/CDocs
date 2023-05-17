#!/bin/sh

podman run --rm -it -v /home/chgray/:/src localhost/chgray123/chgray_repro:pandoc bash -c '/src/CDocs/ConvertDocument.sh'
