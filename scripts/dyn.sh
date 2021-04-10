#!/bin/sh

set -e

# Get ip from parameter
IP=$1
echo "Update ip to $IP."

# Replace old ip from zonefile by new ip, use tee instead of sed -i
# because Docker does not permit the overwriting of inodes.
sed "s/@ IN A .*/@ IN A $IP/" /zonefile | tee /zonefile.tmp >/dev/null

# Get old serial from zonefile and increment value to new serial
SERIAL_OLD=$(cat /zonefile.tmp | grep "; serial" | tr -dc '0-9')
SERIAL_NEW=$((SERIAL_OLD+1))

# Replace old serial with new value in temp zonefile
sed -i "s/$SERIAL_OLD/$SERIAL_NEW/" /zonefile.tmp

# Overrite old zonefile by temp zonefile
cat /zonefile.tmp > /zonefile
