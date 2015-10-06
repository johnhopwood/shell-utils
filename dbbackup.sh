#!/bin/bash

[[ -z "$SYSHOME" ]] && echo "SYSHOME not set" && exit 1
. $SYSHOME/system.conf
. $SYSHOME/db.conf

TS=`date +'%Y%m%d-%H%M%S'`
TABLES=`$SYSHOME/dbrun.sh "show tables like 't_%'"`

for TABLE in $TABLES
do
        FILE=$BACKUPDIR/$TABLE.$TS
        echo "Backing up $TABLE to $FILE"
        $SYSHOME/dbrun.sh "select * into outfile '$FILE' from $TABLE"
done

