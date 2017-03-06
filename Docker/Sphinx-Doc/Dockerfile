# From template version: 1.0.0 (2017-03-03)
# Author:    awmyhr
# Created:   2017-03-03
# Project:   nixTools from *NIXLand
# Copyright: 2016 awmyhr
# License:   Apache-2.0
FROM alpine:latest

ENV container=docker \
    LANG=C.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# NOTE: ca-certificates - for SSL verification
#       dumb-init - init system for containers
RUN apk update \
    && apk upgrade \
    && apk add \
        ca-certificates \
        dumb-init

# NOTE: Normally with an Alpine-based image we want absolute minimalizm,
#       so we wouldn't even have bash. Thus, this is put here as a place-
#       holder for whatever this template is ultimately used for...
# NOTE: Once /var/cache is removed, you will no longer be able to apk add
RUN apk add \
      bash \
      build-base \
      graphviz \
      jpeg-dev \
      linux-headers \
      openjdk8-jre-base \
      python3-dev \
      py3-sphinx \
      zlib-dev \
    && easy_install-3.5 pip \
    && pip install --upgrade pip \
    && pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs pip install -U \
    && pip install --upgrade \
        alabaster \
        Sphinx \
        sphinx-better-theme \
        sphinx-py3doc-enhanced-theme \
        sphinx-rtd-theme \
        sphinxcontrib-fulltoc \
        sphinxcontrib-issuetracker \
        sphinxcontrib-plantuml \
        sphinxcontrib-programoutput \
        pygments-markdown-lexer \
        PyYAML \
    && apk del \
        build-base \
        linux-headers \
        jpeg-dev \
        python3-dev \
        zlib-dev \
    && rm -r /var/cache
COPY PlantUML/plantuml /usr/bin/plantuml
COPY PlantUML/plantuml.jar /usr/share/java/plantuml.jar
RUN  chmod 755 /usr/bin/plantuml /usr/share/java/plantuml.jar

ENTRYPOINT ["/usr/bin/dumb-init"]
CMD ["/bin/bash"]

LABEL org.label-schema.name="Sphinx-Doc" \
      org.label-schema.vendor="awmyhr <awmyhr@gmail.com" \
      org.label-schema.version="1.0.0" \
      org.label-schema.release="2017-03-03" \
      org.label-schema.url="https://github.com/awmyhr/nixTools" \
      org.label-schema.vcs-type="git" \
      org.label-schema.vcs-url="https://github.com/awmyhr/nixTools" \
      org.label-schema.summary="Sphinx document build stack." \
      org.label-schema.description="Minimal Sphinx document build stack, with PlantUML, but without PDF support." \
      org.label-schema.schema-version='1.0.0-rc.1'
