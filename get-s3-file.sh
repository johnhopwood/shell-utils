#!/bin/bash

[[ -z "$SYSHOME" ]] && echo "SYSHOME not set" && exit 1

. $SYSHOME/system.conf

# Retreive file if updated. Usage:
# get-s3-file.sh URL FILE ETAGFILE CLEAN STATUS
# ETAGFILE can be empty, e.g. on first attempt to get a file
# If CLEAN="Y" strip "\r" from filers
# If STATUS is set, script returns [updated | unchanged | error] on stdout
# get-s3-file.sh "https://s3.amazonaws.com/b/o" /tmp/o /tmp.o.etag Y Y

rmTmpFiles
HEADERS=`makeTmpFile`
BODY=`makeTmpFile`

URL="$1"
FILE="$2"
ETAGFILE="$3"
CLEAN="$4"
STATUS="$5"
ETAG=`cat "$ETAGFILE" 2>/dev/null`
CURLTIMEOUT=10

curl -s -m $CURLTIMEOUT -D $HEADERS -o $BODY -H "If-None-Match: \"$ETAG\"" "$URL" || logErrorExit "Curl error $?"

HTTPSTATUS=`head -1 $HEADERS | cut -f2 -d ' '`

#file unchanged
if [ "$HTTPSTATUS" = "304" ]; then

	[ -n "$STATUS" ] && echo "unchanged"
	exit 0
fi

#file updated
if [ "$HTTPSTATUS" = "200" ]; then

	#remove windows garbage if requested
	if [ "$CLEAN" = "Y" ]; then
		TMP=`makeTmpFile`
		cat $BODY | tr -d '\r' > $TMP
		mv -f $TMP $BODY
	fi
	
	mv $BODY $FILE
	grep '^ETag' $HEADERS | cut -f2 -d'"' > $ETAGFILE

	[ -n "$STATUS" ] && echo "updated"
	exit 0
fi

#error
[ -n "$STATUS" ] && echo "error"
logErrorExit "Http status code $HTTPSTATUS"
