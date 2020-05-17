
HOSTNAME = live.example.com

all: down configure up

configure:
	bash live-relay-tls.bash make "$(HOSTNAME)"
	bash live-relay-cfg.bash

down:
	docker-compose -f live-relay.yaml down --remove-orphans

up:
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

