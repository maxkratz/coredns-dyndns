#!/bin/sh

set -e

# Get IP from parameter
IP=$1

# Check if provided parameter was empty
if [ -z "$IP" ]
then
    echo "=> No IP provided. Aborting." >&2 
    exit 1;
fi

# Check if IP is valid
IP_REGEX="^((25[0-5]|2[0-4][0-9]|[1]?[1-9][0-9]?).){3}(25[0-5]|2[0-4][0-9]|[1]?[1-9]?[0-9])$"
VALID=$(echo $IP | grep -oE "$IP_REGEX" || true)
if [ -z "$VALID" ]
then
    echo "=> Provided IP is not a valid IPv4 address. Aborting." >&2 
    exit 2;
else
    echo "=> Update ip to $IP."
fi

# Replace old IP from zonefile by new IP, use tee instead of sed -i
# because Docker does not permit the overwriting of inodes.
sed "s/@ IN A .*/@ IN A $IP/" /zonefile | tee /zonefile.tmp >/dev/null

# Get old serial from zonefile and set value to current date/time stamp
SERIAL_OLD=$(cat /zonefile.tmp | grep "; serial" | tr -dc '0-9')
SERIAL_NEW=$(date +%Y%m%d%M%S)

# Replace old serial with new value in temp zonefile
sed -i "s/$SERIAL_OLD/$SERIAL_NEW/" /zonefile.tmp

# Overrite old zonefile by temp zonefile
cat /zonefile.tmp > /zonefile
