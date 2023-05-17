#This is a sample Image
FROM alpine
LABEL maintainer chgray@gmail.com

# ------------------------------------------------------------------------------
#
# Helpful commands: this section is the 'junk drawer' of handy command
#    one could argue they shouldnt be here
#
#
#
#podman build -t "chgray123/chgray_repro:pandoc" .

#podman run -i -v //c/DevDir:/home/runner/work/DevDir -t chgray123/chgray_repro:pandoc /bin/bash
#podman run -i -v ~/DevDir:/home/runner/work/DevDir -t chgray123/chgray_repro:pandoc /bin/bash

# Pusing the container
# podman push chgray123/chgray_repro:pandoc

#	/usr/local/lib/node_modules/mermaid-filter/node_modules/.bin/mmdc
#pandoc -t slidy -s ./IntroSlides.md -o ./X.html --lua-filter /lua-filters/include-files.lua -F mermaid-filter --filter pandoc-plantuml
#pandoc -t slidy -s ./BugCorralOverview.md -o ./X.html --lua-filter /lua-filters/include-files.lua -F mermaid-filter --filter pandoc-plantuml
#pandoc -t slidy -s ./TelemetryWorkshop_#1.md -o ./TelemetryWorkshop_Slides.html --lua-filter /lua-filters/include-files.lua -F mermaid-filter --filter pandoc-plantuml

#PlantUML
#	a) Run a docker
#	   docker run -d -p 8080:8080 plantuml/plantuml-server:tomcat
#	b) Configure in VSCode
#	   "plantuml.render": "PlantUMLServer",
#    "plantuml.server": "http://localhost:8080"

# Puppeteer
# https://github.com/alekzonder/docker-puppeteer

# Mermaid, with config
# https://github.com/vassilevsky/mmdc/blob/master/Dockerfile


#pandoc -t json
#https://github.com/tewarid/docker-pandoc

#"/usr/local/lib/node_modules/mermaid-filter/node_modules/.bin/mmdc"    -w 800 -f -i /tmp/tmp-3202jXrRkQGrlXQb.tmp -t default -o /tmp/tmp-3202jXrRkQGrlXQb.tmp.png /tmp/tmp-3202jXrRkQGrlXQb.tmp.png
#"/usr/local/lib/node_modules/mermaid-filter/node_modules/.bin/mmdc"    -w 800 -f -i /tmp/tmp-464aMUdXGJJuPCI.tmp  -t default -o /tmp/tmp-3202jXrRkQGrlXQb.tmp.png /tmp/tmp-3202jXrRkQGrlXQb.tmp.png
# ------------------------------------------------------------------------------

ENV TZ=America/Los_Angeles

COPY include-files.lua /lua-filters/

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && export DEBIAN_FRONTEND=noninteractive \
    apk add \
    python3 \
    npm \
    wget \
    yarn


#RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apk add sudo
RUN apk add dos2unix
RUN apk add pandoc
RUN apk add bash
RUN apk add npm
RUN apk add chromium
RUN apk add nano


RUN adduser pptruser --disabled-password 
USER pptruser
WORKDIR /home/pptruser
RUN npm install @mermaid-js/mermaid-cli

# We don't need the standalone Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

RUN npm install mermaid-filter
ENV PATH $PATH:/home/pptruser/node_modules/.bin

RUN npm install puppeteer

#COPY puppeteer-config.json /puppeteer.config.js
COPY Pandoc.cmake /Pandoc.cmake
COPY ConvertDocument.sh /ConvertDocument.sh



WORKDIR /

#
# https://github.com/puppeteer/puppeteer/tree/main
# https://pptr.dev/api/puppeteer.puppeteernode
# NODE_PATH=~/node_modules/ node ./puppeteer.js