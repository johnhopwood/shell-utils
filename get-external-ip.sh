#!/bin/bash

[[ -z "$SYSHOME" ]] && echo "SYSHOME not set" && exit 1

. $SYSHOME/system.conf

rmTmpFiles
HEADERS=`makeTmpFile`
BODY=`makeTmpFile`

CURLTIMEOUT=10
USERAGENT="Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"

#OFFSETURLS is a space separated list of OFFSET!URL pairs where OFFSET is the starting line of the 10 line section within the page URL which should be scanned for a valid IP address

OFFSETURLS="\
	32!http://www.ipchicken.com \
	180!http://whatismyipaddress.com \
	210!http://www.canyouseeme.org \
	0!http://checkip.dyndns.com \
	380!http://ipaddress.com \
	100!http://www.checkip.com \
	80!http://www.ip-adress.com \
	120!http://www.hostip.info \
	160!http://www.myipnumber.com \
	1!http://www.showmemyip.com \
	1!http://ip4.me/ \
	85!http://www.yougetsignal.com/what-is-my-ip-address/"

getIP(){

	local OFFSET=$1
	local URL="$2"

	curl -A "$USERAGENT" -s -m $CURLTIMEOUT -D $HEADERS -o $BODY $URL || return
	
	HTTPSTATUS=`head -1 $HEADERS | cut -f2 -d ' '`
	
	[[ "$HTTPSTATUS" == "200" ]] || return
	
	tail -n +$OFFSET $BODY | head -10 | grep -o -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | uniq
}

for OFFSETURL in `shuf -e $OFFSETURLS`; do

	OFFSET=`echo "$OFFSETURL"| cut -f1 -d'!'`
	URL=`echo "$OFFSETURL"| cut -f2 -d'!'`
	
	IP=`getIP "$OFFSET" "$URL"`
	
	#echo $URL $IP; continue
	
	[ -z "$IP" ] && continue
	
	if [ "$IP" = "$LASTIP" ]; then
		echo $IP
		exit 0
	fi
	
	LASTIP="$IP"
done

exit 1
