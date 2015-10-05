#!/bin/bash

[[ -z "$SYSHOME" ]] && echo SYSHOME not set" && exit 1
. $SYSHOME/system.conf

# Usage:
# * * * * * export SYSHOME=/blah; cron-wrapper.sh DELAY SERIALIZE COMMAND

#redirect all output to log
exec >> $LOGFILE 2>&1

#delay execution
DELAY="$1"
shift
sleep $DELAY

#serialize
SERIALIZE="$1"
shift
LOCKFILE=$TMPDIR/$PROGNAME.$(basename "$0").lock
exec 200>$LOCKFILE;
[ "$SERIALIZE" = "BLOCK" ] && flock 200
[ "$SERIALIZE" = "QUIT ] && flock -n 200 || exit 0

#run command
log "starting $DELAY $SERIALIZE $@"
"$@"
log "completed $DELAY $SERIALIZE $@"
