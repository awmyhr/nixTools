# From template version: 1.0.0 (2017-03-03)
# Author:    awmyhr
# Created:   2017-03-03
# Project:   nixTools from *NIXLand
# Copyright: 2016 awmyhr
# License:   Apache-2.0
# Many ideas found from jfloff/alpine-python on GitHub
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

RUN apk add bash \
        build-base \
        linux-headers \
        python2 \
        python2-dev \
        py-setuptools \
    && if [[ ! -e /usr/bin/python ]];        then ln -sf /usr/bin/python2.7 /usr/bin/python; fi \
    && if [[ ! -e /usr/bin/python-config ]]; then ln -sf /usr/bin/python2.7-config /usr/bin/python-config; fi \
    && if [[ ! -e /usr/bin/easy_install ]];  then ln -sf /usr/bin/easy_install-2.7 /usr/bin/easy_install; fi \
    && easy_install pip \
    && if [[ ! -e /usr/bin/pip ]]; then ln -sf /usr/bin/pip2.7 /usr/bin/pip; fi \
    && pip install --upgrade pip setuptools

# NOTE: If this is to be an actual application image, uncomment the following
# RUN apk del bash \
#             build-base \
#             linux-headers \
#     && rm  -r /var/cache

ENTRYPOINT ["/usr/bin/dumb-init"]
CMD ["/bin/bash"]

LABEL org.label-schema.name="Alpine-Python2" \
      org.label-schema.vendor="awmyhr <awmyhr@gmail.com" \
      org.label-schema.version="1.0.0" \
      org.label-schema.release="2017-03-03" \
      org.label-schema.url="https://github.com/awmyhr/nixTools" \
      org.label-schema.vcs-type="git" \
      org.label-schema.vcs-url="https://github.com/awmyhr/nixTools" \
      org.label-schema.summary="Minimal Python2 w/pip playground." \
      org.label-schema.description="Basic install of Python2 with some build tools and pip (updated) for experimentation." \
      org.label-schema.schema-version='1.0.0-rc.1'
