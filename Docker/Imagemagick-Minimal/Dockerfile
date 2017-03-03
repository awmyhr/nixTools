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

# add bash to run imagemagick scripts
# add bc cuz some of Fred Weinhaus' scripts require it
# add ghostscript-fonts as some imagemagick commands throw errors w/out it
RUN apk add \
      bash \
      bc \
      ghostscript-fonts \
      imagemagick \
    && rm -r /var/cache

# add imagemagick scripts
COPY scripts/* /usr/local/bin

ENTRYPOINT ["/usr/bin/dumb-init"]
# give a default usage message
CMD [ "echo", "Provides the Image Magick commands animate, compare, composite, conjure, convert, display, identify, import, mogrify, montage, and stream "]

LABEL org.label-schema.name="Imagemagick-Minimal" \
      org.label-schema.vendor="awmyhr <awmyhr@gmail.com" \
      org.label-schema.version="1.0.0" \
      org.label-schema.release="2017-03-03" \
      org.label-schema.url="https://github.com/awmyhr/nixTools" \
      org.label-schema.vcs-type="git" \
      org.label-schema.vcs-url="https://github.com/awmyhr/nixTools" \
      org.label-schema.summary="Alpine-based Imagemagick" \
      org.label-schema.description="Imagemagick with bash/bc for running scripts" \
      org.label-schema.schema-version='1.0.0-rc.1'
