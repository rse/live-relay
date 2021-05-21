##
##  Dockerfile -- Docker Build Configuration
##

#   build arguments (early)
ARG         IMAGE_PREFIX=engelschall/
ARG         IMAGE_NAME=live-relay-es-service
ARG         IMAGE_VERSION=1.0.7
ARG         IMAGE_RELEASE=20210522

#   ==== STAGE 1 ====

#   derive image from a certain base image
FROM        alpine:3.13 AS stage1

#   add additional build tools
RUN         apk update && \
            apk upgrade && \
            apk add curl binutils gcc g++ cmake make libxslt && \
            apk add musl-dev openssl-dev c-ares-dev uthash-dev zlib-dev linux-headers

#   create build environment
WORKDIR     /tmp/build

#   build cJSON
ENV         VERSION_CJSON=1.7.14
RUN         curl -sSkL https://github.com/DaveGamble/cJSON/archive/refs/tags/v${VERSION_CJSON}.tar.gz | \
                tar zxf -
RUN         cd cJSON-${VERSION_CJSON} && \
            cmake \
                -DCMAKE_BUILD_TYPE="Release" \
                -DCMAKE_INSTALL_PREFIX="/app" \
                -DCMAKE_C_FLAGS="-Wno-deprecated-declarations" \
                -DBUILD_SHARED_LIBS=OFF \
                . && \
            make && \
            make install

#   build libwebsockets
ENV         VERSION_LIBWEBSOCKETS=4.2.0
RUN         curl -sSkL https://github.com/warmcat/libwebsockets/archive/v${VERSION_LIBWEBSOCKETS}.tar.gz | \
                tar zxf -
RUN         cd libwebsockets-${VERSION_LIBWEBSOCKETS} && \
            cmake \
                -DCMAKE_BUILD_TYPE="Release" \
                -DCMAKE_INSTALL_PREFIX="/app" \
                -DCMAKE_C_FLAGS="-Wno-deprecated-declarations" \
                -DBUILD_SHARED_LIBS=OFF \
                -DLWS_WITH_SHARED=OFF \
                -DLWS_WITH_STATIC=ON \
                -DLWS_WITH_SSL=ON \
                -DLWS_WITH_ZLIB=ON \
                -DLWS_WITH_HTTP2=ON \
                -DLWS_WITH_LIBEV=OFF \
                -DLWS_WITH_LIBUV=OFF \
                -DLWS_WITH_EXTERNAL_POLL=ON \
                -DLWS_WITHOUT_TESTAPPS=ON \
                -DDISABLE_WERROR=ON \
                . && \
            make && \
            make install

#   build Mosquitto
ENV         VERSION_MOSQUITTO=2.0.10
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
FROM        golang:1.16.4-alpine3.13 AS stage2

#   add additional build tools
RUN         apk update && \
            apk upgrade && \
            apk add curl git binutils

#   create build environment
ENV         GOPATH=/tmp/build
WORKDIR     /tmp/build

#   build SupervisorD
RUN         git clone --depth 1 https://github.com/ochinchina/supervisord \
                $GOPATH/src/github.com/ochinchina/supervisord
RUN         (   cd $GOPATH/src/github.com/ochinchina/supervisord && \
                go get -v -d && \
                go build -v -o /tmp/build/supervisord )
RUN         strip supervisord

#   ==== STAGE 3 ====

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

