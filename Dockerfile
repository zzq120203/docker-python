FROM python:3.8-slim

RUN sed -i "1ideb http://mirrors.aliyun.com/debian/ stretch main non-free contrib\n\
            deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib\n\
            deb http://mirrors.aliyun.com/debian-security stretch/updates main\n\
            deb-src http://mirrors.aliyun.com/debian-security stretch/updates main\n\
            deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib\n\
            deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib\n\
            deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib\n\
            deb-src http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib" \
            /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
                ca-certificates \
# Workaround for golang not producing a static ctr binary on Go 1.15 and up https://github.com/containerd/containerd/issues/5824
#               libc6-compat \
# DOCKER_HOST=ssh://... -- https://github.com/docker/cli/pull/1014
                openssh-client \
                wget \
    && apt-get clean

# set up nsswitch.conf for Go's "netgo" implementation (which Docker explicitly uses)
# - https://github.com/docker/docker-ce/blob/v17.09.0-ce/components/engine/hack/make.sh#L149
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
# - docker run --rm debian:stretch grep '^hosts:' /etc/nsswitch.conf
#RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV DOCKER_VERSION 20.10.11
# TODO ENV DOCKER_SHA256
# https://github.com/docker/docker-ce/blob/5b073ee2cf564edee5adca05eee574142f7627bb/components/packaging/static/hash_files !!
# (no SHA file artifacts on download.docker.com yet as of 2017-06-07 though)

RUN set -eux; \
        \
        apkArch="$(uname -m)"; \
        case "$apkArch" in \
                'x86_64') \
                        url='https://download.docker.com/linux/static/stable/x86_64/docker-20.10.11.tgz'; \
                        ;; \
                'armhf') \
                        url='https://download.docker.com/linux/static/stable/armel/docker-20.10.11.tgz'; \
                        ;; \
                'armv7') \
                        url='https://download.docker.com/linux/static/stable/armhf/docker-20.10.11.tgz'; \
                        ;; \
                'aarch64') \
                        url='https://download.docker.com/linux/static/stable/aarch64/docker-20.10.11.tgz'; \
                        ;; \
                *) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;; \
        esac; \
        \
        wget -O docker.tgz "$url"; \
        \
        tar --extract \
                --file docker.tgz \
                --strip-components 1 \
                --directory /usr/local/bin/ \
        ; \
        rm docker.tgz; \
        \
        dockerd --version; \
        docker --version
