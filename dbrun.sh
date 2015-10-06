#!/bin/bash

[[ -z "$SYSHOME" ]] && echo "SYSHOME not set" && exit 1
. $SYSHOME/system.conf
. $SYSHOME/db.conf

if [ $# -lt 1 ]; then
        echo "Usage:"
        echo "  $0 \"sql\""
        echo "  $0 -f file.sql"
        exit 0
fi

rmTmpFiles
SQL=`makeTmpFile`

echo "USE $DB;" > $SQL

if [[ x"$1" = x"-f" && -e "$2" ]]; then
        cat "$2" >> $SQL
else
        echo "$*;" >> $SQL
fi

$MYSQL -N < $SQL

