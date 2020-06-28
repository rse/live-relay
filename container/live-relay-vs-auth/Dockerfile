
#   container information
ARG         IMAGE_PREFIX=engelschall/
ARG         IMAGE_NAME=live-relay-vs-auth
ARG         IMAGE_VERSION=1.0.2
ARG         IMAGE_RELEASE=20200628

#   start with the standard Node.js container image
FROM        node:14.4-alpine3.12

#   update system
RUN         apk update && \
            apk upgrade && \
            apk add bash

#   provide build environment
RUN         apk add --no-cache --virtual .build-env \
                binutils-gold gcc make \
                linux-headers libgcc \
                shadow xz tar

#   create application program area
RUN         groupadd -g 2000 app
RUN         useradd -u 2000 -g app -d /app -m -s /bin/sh -p '!' -l app
RUN         mkdir -p /app
ENV         HOME=/app

#   create application data rea
RUN         mkdir -p /data

#   fixate ownership
RUN         chown -R app:app /app
RUN         chown -R app:app /data

#   establish build environment
USER        app:app
WORKDIR     /app
COPY        src.tar.xz .
RUN         xz -d -c <src.tar.xz | tar xf -; rm -f src.tar.xz

#   reconfigure NPM
RUN         (   echo "spin=false"; \
                echo "save=false"; \
                echo "loglevel=error" ) >/app/.npmrc

#   build application
RUN         (   NODE_ENV=production npm install )

#   remove build environment
USER        root
RUN         apk del .build-env

#   cleanup system
RUN         rm -rf /app/.npm
RUN         rm -rf /app/.config
RUN         rm -rf /var/cache/apk/*

#   provide volume
VOLUME      [ "/data" ]

#   finally switch to target environment
WORKDIR     /app
USER        app:app

#   provide entrypoint and start arguments
ENTRYPOINT  [ "node", "/app/service.js", "-a", "0.0.0.0", "-p", "9090" ]
CMD         []

#   expose HTTP port
EXPOSE     9090

