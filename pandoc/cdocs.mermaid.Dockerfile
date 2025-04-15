
FROM minlag/mermaid-cli
#FROM node:18.20-alpine3.19


LABEL maintainer chgray@gmail.com

ARG PROC_ARCH=amd64

# ------------------------------------------------------------------------------
#
# Helpful commands: this section is the 'junk drawer' of handy command
#    one could argue they shouldnt be here
#
#
#
# podman build -f cdocs.mermaid.Dockerfile --build-arg PROC_ARCH=arm64 --platform linux/arm64 -t "chgray123/chgray_repro:cdocs.mermaid" .
# podman build -f cdocs.mermaid.Dockerfile -t "chgray123/chgray_repro:cdocs.mermaid" .

USER root
RUN apk update
RUN apk upgrade
RUN apk add bash

COPY CDoc.Launcher.sh /CDoc.Launcher.sh


ENV CDOC_FIRST_CALL=1
CMD [ ]
ENTRYPOINT [ "/CDoc.Launcher.sh" ]

#CMD [ "--help"]
#ENTRYPOINT [ "/home/mermaidcli/node_modules/.bin/mmdc -p /puppeteer-config.json" ]
