#!/bin/bash

HOSTMIN=$1
HOSTMAX=$2

# IP range functions from http://notes.asd.me.uk/2011/01/04/iterating-over-a-range-of-ip-addresses-in-bash/

ip2int()
{
	local IP="$1"

	A=`echo $IP | cut -d. -f1`
	B=`echo $IP | cut -d. -f2`
	C=`echo $IP | cut -d. -f3`
	D=`echo $IP | cut -d. -f4`

	INT=$(( 16777216 * $A ))
	INT=$(( (65536 * $B) + $INT ))
	INT=$(( (256 * $C) + $INT ))
	INT=$(( $D + $INT ))

	echo $INT
}

int2ip()
{
	local INT="$1"

	D=$(( $INT % 256 ))
	C=$(( (($INT - $D) / 256) % 256 ))
	B=$(( (($INT - $C - $D) / 65536) % 256 ))
	A=$(( (($INT - $B - $C - $D) / 16777216) % 256 ))

	echo "$A.$B.$C.$D"
}

IPINTMIN=`ip2int $HOSTMIN`
IPINTMAX=`ip2int $HOSTMAX`

for IPINT in $( seq $IPINTMIN $IPINTMAX ); do
	int2ip $IPINT
done
