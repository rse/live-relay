#!/usr/bin/env bash
##
##  Live Video Experience (LiVE)
##  Copyright (c) 2020 Dr. Ralf S. Engelschall <rse@engelschall.com>
##  Licensed under GPL 3.0 <https://spdx.org/licenses/GPL-3.0>
##
##  live-relay-tls.bash: TLS certificate/key generation
##

#   accept various usage patterns
if [ $# -lt 2 ]; then
    echo "USAGE: sh live-relay-tls.sh take <ca-crt> <sv-crt> <sv-key>"
    echo "USAGE: sh live-relay-tls.sh make <hostname> [...]"
    exit 1
fi

cmd="$1"
shift
if [ ".$cmd" = .take -a $# -eq 3 ]; then
    #   just take the existing files
    cp "$1" live-relay-tls-ca.crt
    cp "$2" live-relay-tls-sv.crt
    cp "$3" live-relay-tls-sv.key
    chmod 644 live-relay-tls-ca.crt
    chmod 644 live-relay-tls-sv.crt
    chmod 600 live-relay-tls-sv.key
    exit 0
elif [ ".$cmd" = .make -a $# -ge 1 ]; then
    :
else
    echo "ERROR: invalid command"
    exit 1
fi

#   generate CA certificate/key pair
if [ ! -f live-relay-tls-ca.crt ]; then
    (   echo "{"
        echo "    \"key\": {"
        echo "        \"algo\": \"rsa\","
        echo "        \"size\": 4096"
        echo "    },"
        echo "    \"ca\": {"
        echo "        \"expiry\": \"87600h\","
        echo "        \"pathlen\": 1"
        echo "    },"
        echo "    \"CN\": \"CA\","
        echo "    \"names\": ["
        echo "        {"
        echo "            \"OU\": \"Certificate Authority\""
        echo "        }"
        echo "    ]"
        echo "}"
    ) >live-relay-tls-ca.json
    cmd="cd /pwd"
    cmd="$cmd; cfssl genkey -loglevel=1 -initca live-relay-tls-ca.json"
    cmd="$cmd | cfssl-json -bare ca"
    cmd="$cmd; chown \$UID:\$GID ca.csr ca-key.pem ca.pem"
    docker run --rm -i -v "`pwd`:/pwd" -e UID="`id -u`" -e GID="`id -g`" \
        engelschall/live-relay-xx-utils sh -c "$cmd"
    rm -f ca.csr
    mv ca-key.pem live-relay-tls-ca.key
    mv ca.pem     live-relay-tls-ca.crt
    chmod 600 live-relay-tls-ca.key
    chmod 644 live-relay-tls-ca.crt
    (   echo "{"
        echo "    \"signing\": {"
        echo "        \"profiles\": {"
        echo "            \"peer\": {"
        echo "                \"expiry\": \"87600h\","
        echo "                \"usages\": ["
        echo "                    \"signing\","
        echo "                    \"key encipherment\","
        echo "                    \"server auth\","
        echo "                    \"client auth\""
        echo "                ]"
        echo "            },"
        echo "            \"server\": {"
        echo "                \"expiry\": \"87600h\","
        echo "                \"usages\": ["
        echo "                    \"signing\","
        echo "                    \"key encipherment\","
        echo "                    \"server auth\""
        echo "                ]"
        echo "            },"
        echo "            \"client\": {"
        echo "                \"expiry\": \"87600h\","
        echo "                \"usages\": ["
        echo "                    \"signing\","
        echo "                    \"key encipherment\","
        echo "                    \"client auth\""
        echo "                ]"
        echo "            }"
        echo "        }"
        echo "    }"
        echo "}"
    ) >live-relay-tls-ca.json
    chmod 644 live-relay-tls-ca.json
fi

#   generate server certificate/key pair
if [ ! -f live-relay-tls-sv.crt ]; then
    (   echo "{"
        echo "    \"key\": {"
        echo "        \"algo\": \"rsa\","
        echo "        \"size\": 4096"
        echo "    },"
        echo "    \"CN\": \"$1\","
        echo "    \"hosts\": ["
        i=0
        for host in "$@"; do
            echo -n "        \"$host\""
            i=`expr $i + 1`
            if [ $i -lt $# ]; then
                echo -n ","
            fi
            echo ""
        done
        echo "    ]"
        echo "}"
    ) >live-relay-tls-sv.json
    cmd="cd /pwd"
    cmd="$cmd; cfssl gencert -loglevel=1"
    cmd="$cmd -ca live-relay-tls-ca.crt -ca-key live-relay-tls-ca.key -config live-relay-tls-ca.json"
    cmd="$cmd -profile=server live-relay-tls-sv.json"
    cmd="$cmd | cfssl-json -bare server"
    cmd="$cmd; chown \$UID:\$GID server.csr server-key.pem server.pem"
    docker run --rm -i -v "`pwd`:/pwd" -e UID="`id -u`" -e GID="`id -g`" \
        engelschall/live-relay-xx-utils sh -c "$cmd"
    rm -f server.csr
    mv server-key.pem live-relay-tls-sv.key
    mv server.pem live-relay-tls-sv.crt
    chmod 600 live-relay-tls-sv.key
    chmod 644 live-relay-tls-sv.crt
fi

