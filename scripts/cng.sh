#!/bin/sh

set -e

# Get VALUE from parameter
VAL=$1

# Check if provided IP parameter was empty
if [ -z "$VAL" ]
then
    echo "badsys"
    exit 0;
fi

# Get previous TXT from zone file
TXT_OLD=$(grep '_acme-challenge IN TXT "' /zonefile_le | cut -d\  -f4)

# Replace old val from zonefile by new val, use tee instead of sed -i
# because Docker does not permit the overwriting of inodes.
sed "s/_acme-challenge IN TXT \".*/_acme-challenge IN TXT \"${VAL}\"/" /zonefile_le > /zonefile_le.tmp

# Get old serial from zonefile and set value to current date/time stamp
SERIAL_OLD=$(cat /zonefile_le.tmp | grep "; serial" | tr -dc '0-9')
SERIAL_NEW=$(date +%y%m%d%H%M)

# Ensure that new serial is always larger than previous one
# (This could happen if there is more than one update per minute)
if [ "$SERIAL_OLD" -ge "$SERIAL_NEW" ]; then
    SERIAL_NEW=$((SERIAL_OLD+1))
fi

# Replace old serial with new value in temp zonefile
sed -i "s/$SERIAL_OLD/$SERIAL_NEW/" /zonefile_le.tmp

# Overwrite old zonefile by temp zonefile
cat /zonefile_le.tmp > /zonefile_le

if [[ "$TXT_OLD" == "$VAL" ]]
then
    echo "nochg"
else
    echo "good"
fi
