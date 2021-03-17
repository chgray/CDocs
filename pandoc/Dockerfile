#This is a sample Image
FROM ubuntu:20.04

LABEL maintainer chgray@gmail.com

# ------------------------------------------------------------------------------
#
# Helpful commands: this section is the 'junk drawer' of handy command
#    one could argue they shouldnt be here
#
#
#
#docker build -t "chgray123/chgray_repro:pandoc" .

#docker run -i -v //c/DevDir:/home/runner/work/DevDir -t chgray123/chgray_repro:pandoc /bin/bash
#docker run -i -v ~/DevDir:/home/runner/work/DevDir -t chgray123/chgray_repro:pandoc /bin/bash

# Pusing the container
# docker push chgray123/chgray_repro:pandoc

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

RUN apt-get update \
    && apt-get -y install sudo

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y -q \
    python3-pip \
    libnss3-dev \
    npm \
    wget \
    yarn

RUN wget -O- https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && rm -rf /var/lib/apt/lists/


RUN apt-get update

RUN apt-get install -y -q cups \
    libxss1 \
    aptitude \
    libasound2-dev \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libpangocairo-1.0-0 \
    libgtk-3-0

RUN apt-get install -y -q yarn

RUN apt-get install -y -q libgbm-dev

RUN apt-get install -y -q cmake \
    cabal-install \
    git


RUN apt-get install -y -q locales

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


RUN cabal update
RUN git clone https://github.com/LaurentRDC/pandoc-plot \
    && cd /pandoc-plot \
    && cabal install

RUN cp /root/.cabal/bin/* /usr/sbin/

RUN (npm install --global mermaid-filter --suppess-warnings --unsafe-perm=true --allow-root) \
    && ln -sf /node_modules/.bin/mmdc /usr/bin/mmdc

RUN yarn add mermaid mermaid.cli

RUN npm install puppeteer --unsafe-perm=true --allow-root

RUN pip3 install panflute

RUN apt-get install -y -q plantuml \
    && pip3 install pandoc-plantuml-filter

RUN apt-get install -y -q dos2unix

RUN apt-get install -y -q python3-matplotlib
RUN apt-get install -y -q python3-pip
RUN DEBIAN_FRONTEND=noninteractive apt-get install keyboard-configuration
RUN apt-get install -y -q gnuplot

RUN pip3 install bokeh
RUN pip3 install selenium
RUN pip3 install pandas

# Install PDFLatex and friends
RUN apt-get install -y -q texlive-latex-base texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra

COPY updated_mermaid_index.js /usr/local/lib/node_modules/mermaid-filter/index.js

RUN chmod +x /usr/local/lib/node_modules/mermaid-filter/index.js

RUN dos2unix /usr/local/lib/node_modules/mermaid-filter/index.js

COPY puppeteer-config.json /puppeteer-config.json

COPY Pandoc.cmake /Pandoc.cmake

WORKDIR /