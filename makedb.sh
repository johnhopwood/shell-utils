#!/bin/bash

[[ -z "$SYSHOME" ]] && echo "SYSHOME not set" && exit 1
. $SYSHOME/system.conf
. $SYSHOME/db.conf

rmTmpFiles
TMP=`makeTmpFile`

#####################################

f [ x"$1" = x"drop" ]; then
        echo "dropping tables"
        echo "loading schema"
        $SYSHOME/dbrun.sh -f $DBHOME/schema.ddl
else
        echo "loading schema"
        grep -iv "DROP TABLE IF EXISTS" $DBHOME/schema.ddl > $TMP
        $SYSHOME/dbrun.sh -f $TMP
fi

#####################################

for FUNC in $DBHOME/f_*.sql; do
        echo "loading function $FUNC"
        $SYSHOME/dbrun.sh -f $FUNC
done

#####################################

for PROC in $DBHOME/p_*.sql; do
        echo "loading sp $PROC"
        $SYSHOME/dbrun.sh -f $PROC
done

#####################################

$SYSHOME/dbrun.sh -f $DBHOME/init.sql

