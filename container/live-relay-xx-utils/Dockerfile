##
##  Dockerfile -- Docker Build Configuration
##

#   build arguments (early)
ARG         IMAGE_PREFIX=engelschall/
ARG         IMAGE_NAME=live-relay-xx-utils
ARG         IMAGE_VERSION=1.0.7
ARG         IMAGE_RELEASE=20210522

#   derive image from a certain base image
FROM        golang:1.16.4-alpine3.13 AS stage1

#   add additional build tools
RUN         apk update && \
            apk upgrade && \
            apk add curl git openssl binutils gcc musl-dev patch

#   create build environment
ENV         GOPATH=/tmp/build
WORKDIR     /tmp/build

#   build CFSSL
RUN         git clone --depth 1 https://github.com/cloudflare/cfssl \
                $GOPATH/src/github.com/cloudflare/cfssl
RUN         (   cd $GOPATH/src/github.com/cloudflare/cfssl && \
                go build -v -o /tmp/build/cfssl cmd/cfssl/cfssl.go && \
                go build -v -o /tmp/build/cfssl-json cmd/cfssljson/cfssljson.go )
RUN         strip cfssl
RUN         strip cfssl-json

#   ==== STAGE 2 ====

#   derive image from a certain base image
FROM        alpine:3.13

#   prepare Alpine
RUN         apk update && \
            apk upgrade

#   extend Alpine
RUN         apk add bash curl su-exec && \
            apk add musl openssl c-ares libwebsockets

#   establish application area and user/group
RUN         apk add --no-cache --virtual .build-deps shadow
RUN         groupadd -g 1000 app
RUN         useradd -u 1000 -g app -d /app -m -s /bin/bash -p '!' -l app
RUN         apk del .build-deps
RUN         mkdir -p /app/bin
WORKDIR     /app

#   install SupervisorD
COPY        --from=stage1 /tmp/build/cfssl      /app/bin/cfssl
COPY        --from=stage1 /tmp/build/cfssl-json /app/bin/cfssl-json
RUN         chmod 755 /app/bin/cfssl

#   strip down binaries
RUN         apk add --no-cache --virtual .build-deps binutils
RUN         strip /app/bin/*
RUN         apk del .build-deps

#   extend environment
ENV         PATH=$PATH:/app/bin

#   cleanup Alpine
RUN         rm -rf /var/cache/apk/*

#   fixate ownerships
RUN         chown -R app:app /app

#   provide entrypoint
CMD         [ "bash" ]

