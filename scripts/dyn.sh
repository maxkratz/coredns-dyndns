#!/bin/sh

set -e

# Get IP from parameter
IP=$1
HOSTNAME=$2

# Check if provided IP parameter was empty
if [ -z "$IP" ]
then
    echo "=> No IP provided. Aborting." >&2 
    exit 1;
fi

if [ ! -z "$HOSTNAME" ]
then
    echo "=> Hostname parameter: $HOSTNAME"
fi

# Check if IP is valid
IP_REGEX="^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
VALID=$(echo $IP | grep -oE "$IP_REGEX" || true)
if [ -z "$VALID" ]
then
    echo "=> Provided IP is not a valid IPv4 address. Aborting." >&2 
    exit 2;
else
    echo "=> Update IP to $IP."
fi

# Replace old IP from zonefile by new IP, use tee instead of sed -i
# because Docker does not permit the overwriting of inodes.
sed "s/@ IN A .*/@ IN A $IP/" /zonefile > /zonefile.tmp

# Get old serial from zonefile and set value to current date/time stamp
SERIAL_OLD=$(cat /zonefile.tmp | grep "; serial" | tr -dc '0-9')
SERIAL_NEW=$(date +%y%m%d%H%M)

# Ensure that new serial is always larger than previous one
# (This could happen if there is more than one update per minute)
if [ "$SERIAL_OLD" -ge "$SERIAL_NEW" ]; then
    echo "=> Incremented old serial."
    SERIAL_NEW=$((SERIAL_OLD+1))
fi

# Replace old serial with new value in temp zonefile
sed -i "s/$SERIAL_OLD/$SERIAL_NEW/" /zonefile.tmp

# Overwrite old zonefile by temp zonefile
cat /zonefile.tmp > /zonefile
