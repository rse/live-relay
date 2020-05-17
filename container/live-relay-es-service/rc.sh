#!/bin/bash
##
##  rc.sh -- Docker Image Run-Command Script
##

#   fetch configuration and provide default values
CFG_ADMIN_USERNAME="${CFG_ADMIN_USERNAME-admin}"
CFG_ADMIN_PASSWORD="${CFG_ADMIN_PASSWORD-admin}"
CFG_CUSTOM_USERNAME="${CFG_CUSTOM_USERNAME-example}"
CFG_CUSTOM_PASSWORD="${CFG_CUSTOM_PASSWORD-example}"

#   configuration
etcdir="/app/etc"
datadir="/data/mosquitto"

#   display verbose message
verbose () {
    echo "INFO[$(date '+%Y-%m-%dT%H:%M:%SZ')] rc: ### $*" 1>&2
}

#   handle fatal error
fatal () {
    echo "ERRO[$(date '+%Y-%m-%dT%H:%M:%SZ')] rc: *** FATAL ERROR: $*" 1>&2
    exit 1
}

#   determine root pid of process
rpid () {
    local pid=${1-$$}
    while true; do
        if [[ ! -d /proc/$pid ]]; then
            break
        fi
        local ppid=$(awk '/^PPid:/ { print $2; }' </proc/$pid/status)
        if [[ $ppid == "0" ]]; then
            echo $pid
            break
        fi
        pid=$ppid
    done
}

#   start and control SupervisorD daemon
supervisord () {
    if [[ $# -eq 0 ]]; then
        #   execute daemon
        exec supervisord \
            -c /app/etc/supervisord.ini
    else
        #   control daemon
        command supervisord \
            ctl -s unix:///app/var/supervisord.sock \
            ${1+"$@"} >/dev/null 2>&1
    fi
}

#   boot the Docker container (outside SupervisorD)
cmd_boot () {
    if [[ $(rpid) != "1" ]]; then
        fatal "command has to be executed in primary container process context"
    fi
    verbose "pass-through control to SupervisorD"
    supervisord
}

#   boot the Docker container (outside SupervisorD)
cmd_start () {
    if [[ $(rpid) != "1" ]]; then
        fatal "command has to be executed in primary container process context"
    fi

    #   pre-fill authentication database on initial startup
    pwdfile="$datadir/etc/mosquitto-pwd.txt"
    if [[ $(stat -c %Y $pwdfile) -eq 0 ]]; then
        verbose "activating administrator account \"$CFG_ADMIN_USERNAME\""
        su-exec app:app mosquitto_passwd -b $pwdfile "$CFG_ADMIN_USERNAME" "$CFG_ADMIN_PASSWORD"
        if [[ $CFG_CUSTOM_USERNAME != "" && $CFG_CUSTOM_PASSWORD != "" ]]; then
            verbose "activating custom account \"$CFG_CUSTOM_USERNAME\""
            su-exec app:app mosquitto_passwd -b $pwdfile "$CFG_CUSTOM_USERNAME" "$CFG_CUSTOM_PASSWORD"
        fi
    fi

    #   start Mosquitto service
    verbose "starting Mosquitto service"
    supervisord start mosquitto
}

#   backup state
cmd_backup () {
    if [[ $(rpid) == "1" ]]; then
        fatal "command has to be executed in secondary container process context"
    fi
    tar cf - -C $datadir . | gzip -9
}

#   restore state
cmd_restore () {
    if [[ $(rpid) == "1" ]]; then
        fatal "command has to be executed in secondary container process context"
    fi
    mv $datadir $datadir.old
    mkdir $datadir
    gunzip - | tar xf - -C $datadir
    rm -rf $datadir.old
    kill 1
}

#   start Mosquitto
cmd_mosquitto () {
    if [[ $(rpid) != "1" ]]; then
        fatal "command has to be executed in primary container process context"
    fi
    exec su-exec app:app mosquitto -c $etcdir/mosquitto.conf
}

#   run mosquitto_pub(1) CLI
cmd_mosquitto_pub () {
    if [[ $(rpid) == "1" ]]; then
        fatal "command has to be executed in secondary container process context"
    fi
    exec su-exec app:app mosquitto_pub ${1+"$@"}
}

#   run mosquitto_sub(1) CLI
cmd_mosquitto_sub () {
    if [[ $(rpid) == "1" ]]; then
        fatal "command has to be executed in secondary container process context"
    fi
    exec su-exec app:app mosquitto_sub ${1+"$@"}
}

#   run mosquitto_rr(1) CLI
cmd_mosquitto_rr () {
    if [[ $(rpid) == "1" ]]; then
        fatal "command has to be executed in secondary container process context"
    fi
    exec su-exec app:app mosquitto_rr ${1+"$@"}
}

#   run mosquitto_passwd(1) CLI
cmd_passwd () {
    if [[ $(rpid) == "1" ]]; then
        fatal "command has to be executed in secondary container process context"
    fi
    if [[ $# -eq 1 ]]; then
        exec su-exec app:app mosquitto_passwd $datadir/etc/mosquitto-pwd.txt $1
    elif [[ $# -eq 2 && $2 == "-" ]]; then
        exec su-exec app:app mosquitto_passwd -D $datadir/etc/mosquitto-pwd.txt $1
    elif [[ $# -eq 2 ]]; then
        exec su-exec app:app mosquitto_passwd -b $datadir/etc/mosquitto-pwd.txt $1 $2
    else
        echo "USAGE: passwd <username> [<password>]" 1>&2
        exit 1
    fi
}

#   dispatch according to command
if [[ $# -eq 0 ]]; then
    set -- start
fi
cmd="$1"; shift
eval "cmd_$(echo $cmd | sed -e 's;-;_;g')" "$@"
exit $?

