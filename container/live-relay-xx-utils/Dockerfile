##
##  Dockerfile -- Docker Build Configuration
##

#   build arguments (early)
ARG         IMAGE_PREFIX=engelschall/
ARG         IMAGE_NAME=live-relay-xx-utils
ARG         IMAGE_VERSION=0.9.0
ARG         IMAGE_RELEASE=20200517

#   derive image from a certain base image
FROM        golang:1.14.3-alpine3.11 AS stage1

#   add additional build tools
RUN         apk update && \
            apk upgrade && \
            apk add curl git openssl binutils gcc musl-dev patch

#   create build environment
ENV         GOPATH=/tmp/build
WORKDIR     /tmp/build

#   build CFSSL
RUN         go get -v -d -u github.com/cloudflare/cfssl/...
RUN         go build -v -o cfssl github.com/cloudflare/cfssl/cmd/cfssl/
RUN         go build -v -o cfssl-json github.com/cloudflare/cfssl/cmd/cfssljson/
RUN         strip cfssl
RUN         strip cfssl-json

#   ==== STAGE 2 ====

#   derive image from a certain base image
FROM        alpine:3.11

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

