#!/bin/bash

[[ -z "$SYSHOME" ]] && echo "SYSHOME not set" && exit 1
. $SYSHOME/system.conf

SHA256(){
	local DATA="$1"
	printf "$DATA" | openssl dgst -hex -sha256 | cut -c10-
}

HMACSHA256(){
	local KEY="$1"
	local DATA="$2"
	printf "$DATA" | openssl dgst -hex -sha256 -mac HMAC -macopt hexkey:$KEY | cut -c10-
}

#http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html
makePutRecordPayload(){

	local STREAM="$1"
	local DATA=`cat "$2" | base64 -w 0`
	local PARTITION_KEY="$3"

cat <<EOF
{
"StreamName":"$STREAM",
"Data":"$DATA",
"PartitionKey":"$PARTITION_KEY"
}
EOF
}

#http://docs.aws.amazon.com/kinesis/latest/APIReference/API_DescribeStream.html
makeDescribeStreamPayload(){

	local STREAM="$1"

cat <<EOF
{
"StreamName":"$STREAM"
}
EOF
}

#http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html
makeGetShardIteratorPayload(){

	local STREAM="$1"
	local SHARDID="$2"
	local TYPE="$3"

cat <<EOF
{
"StreamName":"$STREAM",
"ShardId": "$SHARDID",
"ShardIteratorType": "$TYPE"
}
EOF
}

#http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html
makeGetRecordsPayload(){

        local SHARDITERATOR="$1"
        local LIMIT="$2"

cat <<EOF
{
"ShardIterator": "$SHARDITERATOR",
"Limit": $LIMIT
}
EOF
}


#http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
makeCanonReq(){

	local HOST="$1"
	local LONG_DATE="$2"
	local HASHED_PAYLOAD="$3"

cat <<EOF
POST
/

content-type:application/x-amz-json-1.1
host:$HOST
x-amz-date:$LONG_DATE

content-type;host;x-amz-date
$HASHED_PAYLOAD
EOF
}

#http://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
makeStringToSign(){

	local LONG_DATE="$1"
	local SHORT_DATE="$2"
	local SERVICE="$3"
	local REGION="$4"
	local HASHED_CANON_REQUEST="$5"

cat <<EOF
AWS4-HMAC-SHA256
$LONG_DATE
$SHORT_DATE/$REGION/$SERVICE/aws4_request
$HASHED_CANON_REQUEST
EOF
}

#http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
makeAuthHeader(){

	local KEYID="$1"
	local KEY="$2"
	local SHORT_DATE="$3"
	local REGION="$4"
	local SERVICE="$5"
	local STRING_TO_SIGN="$6"

	KSECRET=`printf "AWS4$KEY" | xxd -p -c 256`
	KDATE=`HMACSHA256 "$KSECRET" "$SHORT_DATE"`
	KREGION=`HMACSHA256 "$KDATE" "$REGION"`
	KSERVICE=`HMACSHA256 "$KREGION" "$SERVICE"`
	KSIGNING=`HMACSHA256 "$KSERVICE" "aws4_request"`
	SIG=`HMACSHA256 "$KSIGNING" "$STRING_TO_SIGN"`

	printf "AWS4-HMAC-SHA256 Credential=$KEYID/$SHORT_DATE/$REGION/$SERVICE/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=$SIG"
}

AWS_SERVICE="kinesis"
LONG_DATE=`date --utc +"%Y%m%dT%H%M%SZ"`
SHORT_DATE=`echo $LONG_DATE | cut -c1-8`

AWS_ACCESS_KEY_ID="$1"
AWS_SECRET_ACCESS_KEY="$2"
AWS_SESSION_TOKEN="$3"
AWS_REGION="$4"
KINESIS_ENDPOINT="$5"
KINESIS_STREAM="$6"
ACTION="$7"


case $ACTION in
put)
	DATAFILE="$8"
	KINESIS_PARTITION_KEY="$9"
	KINESIS_TARGET="Kinesis_20131202.PutRecord"
	PAYLOAD=`makePutRecordPayload "$KINESIS_STREAM" "$DATAFILE" "$KINESIS_PARTITION_KEY"`
	;;

describe)
	KINESIS_TARGET="Kinesis_20131202.DescribeStream"
	PAYLOAD=`makeDescribeStreamPayload "$KINESIS_STREAM"`
	;;

geti)
	SHARDID="$8"
	TYPE="$9"
	KINESIS_TARGET="Kinesis_20131202.GetShardIterator"
	PAYLOAD=`makeGetShardIteratorPayload "$KINESIS_STREAM" "$SHARDID" "$TYPE"`
	;;

getr)
	SHARDITERATOR="$8"
	LIMIT="$9"
	KINESIS_TARGET="Kinesis_20131202.GetRecords"
	PAYLOAD=`makeGetRecordsPayload "$SHARDITERATOR" "$LIMIT"`
	;;
	
*)
	echo "unknown command"
	exit 1
	;;

esac

HASHED_PAYLOAD=`SHA256 "$PAYLOAD"`
CANON_REQUEST=`makeCanonReq "$KINESIS_ENDPOINT" "$LONG_DATE" "$HASHED_PAYLOAD"`
HASHED_CANON_REQUEST=`SHA256 "$CANON_REQUEST"`
STRING_TO_SIGN=`makeStringToSign "$LONG_DATE" "$SHORT_DATE" "$AWS_SERVICE" "$AWS_REGION" "$HASHED_CANON_REQUEST"`
AUTH_HEADER=`makeAuthHeader "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$SHORT_DATE" "$AWS_REGION" "$AWS_SERVICE" "$STRING_TO_SIGN"`

#echo "$PAYLOAD"
#echo "$HASHED_PAYLOAD"
#echo "$CANON_REQUEST"
#echo "$HASHED_CANON_REQUEST"
#echo "$STRING_TO_SIGN"
#echo "$AUTH_HEADER"

rmTmpFiles
HEADERS=`makeTmpFile`
BODY=`makeTmpFile`
CURLTIMEOUT=20

curl -s -m $CURLTIMEOUT -D $HEADERS -o $BODY -H "Expect:" -H "Authorization: $AUTH_HEADER" -H "Content-Type: application/x-amz-json-1.1" -H "x-amz-security-token: $AWS_SESSION_TOKEN" -H "x-amz-target: $KINESIS_TARGET" -H "x-amz-Date: $LONG_DATE" --data "$PAYLOAD" "https://$KINESIS_ENDPOINT" || logErrorExit "Curl error $?"

HTTPSTATUS=`head -1 $HEADERS | cut -f2 -d ' '`

[ "$HTTPSTATUS" != "200" ] && logErrorExit "HTTP status code $HTTPSTATUS"

exit 0

