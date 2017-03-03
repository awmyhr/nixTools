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

RUN apk --update add openjdk8-jre-base \
    && rm -r /var/cache

ENTRYPOINT ["/usr/bin/dumb-init"]
# For now, just get java version
CMD ["/usr/bin/java","-version"]

LABEL org.label-schema.name="Minimal Java (Alpine)" \
      org.label-schema.vendor="awmyhr <awmyhr@gmail.com" \
      org.label-schema.version="1.0.0" \
      org.label-schema.release="2017-03-03" \
      org.label-schema.url="https://github.com/awmyhr/nixTools" \
      org.label-schema.vcs-type="git" \
      org.label-schema.vcs-url="https://github.com/awmyhr/nixTools" \
      org.label-schema.summary="Alpine-based minimal Java" \
      org.label-schema.description="Smallest OpenJava JRE docker image w/o using Black Magic(TM)." \
      org.label-schema.schema-version='1.0.0-rc.1'
