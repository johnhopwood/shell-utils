#!/bin/bash

[[ -z "$SYSHOME" ]] && echo "SYSHOME not set" && exit 1

. $SYSHOME/system.conf

rmTmpFiles
HEADERS=`makeTmpFile`
BODY=`makeTmpFile`

URL="$1"
FILE="$2"
CURLTIMEOUT=10

curl -s -m $CURLTIMEOUT -H "Expect:" -D $HEADERS -o $BODY -T "$FILE" "$URL" || logErrorExit "Curl error $?"

HTTPSTATUS=`head -1 $HEADERS | cut -f2 -d ' '`

# success
[ "$HTTPSTATUS" = "200" ] && exit 0

# error
logErrorExit "Http status code $HTTPSTATUS"
