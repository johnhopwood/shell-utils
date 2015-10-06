#!/bin/bash

[[ -z "$SYSHOME" ]] && echo "SYSHOME not set" && exit 1
. $SYSHOME/system.conf
. $SYSHOME/db.conf

FILTER="$*"

for FILE in `ls $BACKUPDIR/*$FILTER*`
do
        TABLE=`basename $FILE | cut -f1 -d"."`
        echo "Restoring $TABLE from $FILE"
        $DIR/dbrun.sh "truncate table $TABLE"
        $DIR/dbrun.sh "load data infile '$FILE' into table $TABLE"
done

