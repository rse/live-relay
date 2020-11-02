##
##  Dockerfile -- Docker Build Configuration
##

#   build arguments (early)
ARG         IMAGE_PREFIX=engelschall/
ARG         IMAGE_NAME=live-relay-es-service
ARG         IMAGE_VERSION=1.0.5
ARG         IMAGE_RELEASE=20201102

#   ==== STAGE 1 ====

#   derive image from a certain base image
FROM        alpine:3.12 AS stage1

#   add additional build tools
RUN         apk update && \
            apk upgrade && \
            apk add curl binutils gcc g++ cmake make && \
            apk add musl-dev openssl-dev c-ares-dev libwebsockets-dev uthash-dev

#   create build environment
WORKDIR     /tmp/build

#   build Mosquitto
ENV         VERSION_MOSQUITTO=1.6.12
RUN         curl -sSkL https://mosquitto.org/files/source/mosquitto-${VERSION_MOSQUITTO}.tar.gz | \
                tar zxf -
RUN         cd mosquitto-${VERSION_MOSQUITTO} && \
            cmake \
                -DCMAKE_BUILD_TYPE="Release" \
                -DCMAKE_INSTALL_PREFIX="/app" \
                -DCMAKE_C_FLAGS="-Wno-deprecated-declarations" \
                -DCMAKE_CXX_FLAGS="-Wno-deprecated-declarations" \
                -DBUILD_SHARED_LIBS=OFF \
                -DWITH_STATIC_LIBRARIES=ON  \
                -DWITH_PIC=ON \
                -DWITH_WEBSOCKETS=ON \
                -DWITH_TLS=ON \
                -DWITH_TLS_PSK=ON \
                -DWITH_EC=ON \
                -DWITH_SRV=ON \
                . && \
            make && \
            make install

#   ==== STAGE 2 ====

#   derive image from a certain base image
FROM        golang:1.14.7-alpine3.12 AS stage2

#   add additional build tools
RUN         apk update && \
            apk upgrade && \
            apk add curl git binutils

#   create build environment
ENV         GOPATH=/tmp/build
WORKDIR     /tmp/build

#   build SupervisorD
RUN         go get -v -d github.com/ochinchina/supervisord
RUN         go build -v -o supervisord github.com/ochinchina/supervisord
RUN         strip supervisord

#   ==== STAGE 3 ====

#   derive image from a certain base image
FROM        alpine:3.12

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
RUN         mkdir -p /app/sbin /app/etc
WORKDIR     /app

#   establish application area
RUN         mkdir -p /app/bin /app/sbin /app/etc /app/var /app/share

#   establish data area
RUN         mkdir -p /data/mosquitto/db
RUN         mkdir -p /data/mosquitto/log
RUN         mkdir -p /data/mosquitto/run
RUN         mkdir -p /data/mosquitto/etc

#   install Mosquitto
COPY        --from=stage1 /app /app
RUN         rm -rf /app/etc/mosquitto /app/share /app/include

#   install SupervisorD
COPY        --from=stage2 /tmp/build/supervisord /app/sbin/supervisord
RUN         chmod 755 /app/sbin/supervisord
COPY        supervisord.ini /app/etc/supervisord.ini

#   strip down binaries
RUN         apk add --no-cache --virtual .build-deps binutils
RUN         strip /app/sbin/*
RUN         apk del .build-deps

#   install configurations
COPY        mosquitto.conf    /app/etc/mosquitto.conf
COPY        mosquitto-acl.txt /app/etc/mosquitto-acl.txt

#   setup initial authentication database
RUN         cp /dev/null /data/mosquitto/etc/mosquitto-pwd.txt && \
            chown app:app /data/mosquitto/etc/mosquitto-pwd.txt && \
            chmod 600 /data/mosquitto/etc/mosquitto-pwd.txt && \
            touch -d "@0" /data/mosquitto/etc/mosquitto-pwd.txt

#   install run-command script
COPY        rc.sh /app/sbin/rc
RUN         chmod 755 /app/sbin/rc

#   extend environment
ENV         PATH=$PATH:/app/sbin:/app/bin

#   cleanup Alpine
RUN         rm -rf /var/cache/apk/*

#   fixate ownerships
RUN         chown -R app:app /app /data

#   provide volume
VOLUME      [ "/data" ]

#   provide entrypoint
CMD         [ "/app/sbin/rc", "boot" ]

#   expose HTTP port
EXPOSE      8888

