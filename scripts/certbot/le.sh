#!/bin/bash

set -e

# Config
USER="TODO"
PW="TODO"
HOST="http://dyn.ns1.example.com"

# Hook
curl -u "$USER:$PW" $HOST/nic/le\?value\="$CERTBOT_VALIDATION"

# Wait to let DNS propagate
sleep 60
