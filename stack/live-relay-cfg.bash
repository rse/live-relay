#!/usr/bin/env bash
##
##  Live Video Experience (LiVE)
##  Copyright (c) 2020 Dr. Ralf S. Engelschall <rse@engelschall.com>
##  Licensed under GPL 3.0 <https://spdx.org/licenses/GPL-3.0>
##
##  live-relay-cfg.bash: Authentication & Authorization
##

#   read access tokens
config=()
OIFS="$IFS"; IFS="
"
for line in `sed -e '/^#.*/d' -e '/^ *$/d' <live-relay-cfg.txt`; do
    config+=($line)
done
IFS="$OIFS"

#   generate Mosquitto access-control-list
(   echo "##"
    echo "##  mosquitto-acl.txt -- Access Control List"
    echo "##"
    echo ""
    echo "topic   read      $SYS/#"
    for line in ${config[*]}; do
        stream=`echo "$line" | sed -e 's;-.*$;;'`
        username=`echo "$line" | sed -e 's;^[^-]*-;;' -e 's;-.*$;;'`
        password=`echo "$line" | sed -e 's;^.*-;;'`
        echo ""
        echo "user    $username"
        echo "topic   readwrite stream/$stream/#"
    done
    echo ""
    echo "pattern write     $SYS/broker/connection/%c/state"
    echo ""
) >live-relay-es-acl.txt

#   generate Mosquitto password database
cp /dev/null live-relay-es-passwd.txt
for line in ${config[*]}; do
    stream=`echo "$line" | sed -e 's;-.*$;;'`
    username=`echo "$line" | sed -e 's;^[^-]*-;;' -e 's;-.*$;;'`
    password=`echo "$line" | sed -e 's;^.*-;;'`
    docker run --rm -i -t -v `pwd`:/pwd engelschall/live-relay-es-service \
        mosquitto_passwd -b /pwd/live-relay-es-passwd.txt "$username" "$password" >/dev/null
done

#   generate SRS authentication configuration
(   echo "##"
    echo "##  srs-auth.yaml -- SRS Authentication Service Configuration"
    echo "##"
    echo ""
    echo "-   ip:     \"127.0.0.1\""
    echo "    app:    \"*\""
    echo "    stream: \"*\""
    echo "    keys:"
    echo "        -   \"*\""
    echo ""
    for line in ${config[*]}; do
        stream=`echo "$line" | sed -e 's;-.*$;;'`
        username=`echo "$line" | sed -e 's;^[^-]*-;;' -e 's;-.*$;;'`
        password=`echo "$line" | sed -e 's;^.*-;;'`
        echo ""
        echo "-   ip:     \"*\""
        echo "    app:    \"stream\""
        echo "    stream: \"$stream*\""
        echo "    keys:"
        echo "        -   \"$username-$password\""
    done
    echo ""
) >live-relay-vs-auth.yaml

#   generate Mosquitto TLS files
cp live-relay-tls-ca.crt live-relay-es-tls-ca.crt
cp live-relay-tls-sv.crt live-relay-es-tls-sv.crt
cp live-relay-tls-sv.key live-relay-es-tls-sv.key
chmod 644 live-relay-es-tls-ca.crt
chmod 644 live-relay-es-tls-sv.crt
chmod 644 live-relay-es-tls-sv.key # has to be readable!

#   generate SRS TLS files
cat live-relay-tls-sv.crt live-relay-tls-ca.crt >live-relay-vs-tls-sv.chn
cp live-relay-tls-sv.key live-relay-vs-tls-sv.key
chmod 644 live-relay-vs-tls-sv.chn
chmod 600 live-relay-vs-tls-sv.key

