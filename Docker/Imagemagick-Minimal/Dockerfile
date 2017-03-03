# From template version: 1.0.0 (2017-03-03)
# Author:    awmyhr
# Created:   2017-03-03
# Project:   nixTools from *NIXLand
# Copyright: 2016 awmyhr
# License:   Apache-2.0
FROM alpine:latest

ENV container=docker \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apk update \
    && apk upgrade

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

# give a default usage message
CMD [ "echo", "Provides the Image Magick commands animate, compare, composite, conjure, convert, display, identify, import, mogrify, montage, and stream "]

LABEL org.label-schema.name="nixTools from *NIXLand" \
      org.label-schema.vendor="awmyhr <awmyhr@gmail.com" \
      org.label-schema.version="1.0.0" \
      org.label-schema.release="2017-03-03" \
      org.label-schema.url="https://github.com/awmyhr/nixTools" \
      org.label-schema.vcs-type="git" \
      org.label-schema.vcs-url="https://github.com/awmyhr/nixTools" \
      org.label-schema.summary="TODO: CHANGEME <100 char" \
      org.label-schema.description="TODO: CHANGEME <300 char" \
      org.label-schema.schema-version='1.0.0-rc.1'
