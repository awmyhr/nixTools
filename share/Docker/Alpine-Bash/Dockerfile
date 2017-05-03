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
RUN apk add bash

ENTRYPOINT ["/usr/bin/dumb-init"]
CMD ["/bin/bash"]

LABEL org.label-schema.name="Alpine-Bash" \
      org.label-schema.vendor="awmyhr <awmyhr@gmail.com" \
      org.label-schema.version="1.0.0" \
      org.label-schema.release="2017-03-03" \
      org.label-schema.url="https://github.com/awmyhr/nixTools" \
      org.label-schema.vcs-type="git" \
      org.label-schema.vcs-url="https://github.com/awmyhr/nixTools" \
      org.label-schema.summary="Simple Alpine container w/bash" \
      org.label-schema.description="Primarily for testing purposes." \
      org.label-schema.schema-version='1.0.0-rc.1'
