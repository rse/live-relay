
LIVE_RELAY_HOST_FQDN  = live.example.com
LIVE_RELAY_PORT_RTMPS = 443
LIVE_RELAY_PORT_MQTTS = 8883

all: down configure up

configure:
	bash live-relay-tls.bash make $(LIVE_RELAY_HOST_FQDN)
	bash live-relay-cfg.bash

down:
	LIVE_RELAY_HOST_FQDN=$(LIVE_RELAY_HOST_FQDN) \
	LIVE_RELAY_PORT_RTMPS=$(LIVE_RELAY_PORT_RTMPS) \
	LIVE_RELAY_PORT_MQTTS=$(LIVE_RELAY_PORT_MQTTS) \
	docker-compose -f live-relay.yaml down --remove-orphans

up:
	LIVE_RELAY_HOST_FQDN=$(LIVE_RELAY_HOST_FQDN) \
	LIVE_RELAY_PORT_RTMPS=$(LIVE_RELAY_PORT_RTMPS) \
	LIVE_RELAY_PORT_MQTTS=$(LIVE_RELAY_PORT_MQTTS) \
	docker-compose -f live-relay.yaml up -d

clean:
	-rm -f live-relay-tls-ca.*
	-rm -f live-relay-tls-sv.*
	-rm -f live-relay-es-tls-ca.*
	-rm -f live-relay-es-tls-sv.*
	-rm -f live-relay-vs-tls-ca.*
	-rm -f live-relay-vs-tls-sv.*
	-rm -f live-relay-es-acl.txt
	-rm -f live-relay-es-passwd.txt
	-rm -f live-relay-vs-auth.yaml

