#!/bin/bash

# Author: THRYSOEE (http://thrysoee.dk/apns/)

deviceToken=c7cd3aa351920b8ba843f43e642dd554f2a92c9c23a871eefd530ecc68a9253b
authKey="./AuthKey_8L58HW42PL.p8"
authKeyId=8L58HW42PL
teamId=9722T8G52H
bundleId=com.knila.HealthMonitor
priority=5
pushType=background

endpoint=https://api.development.push.apple.com

read -r -d '' payload <<-'EOF'
{"aps":{"content-available": 1}}
EOF

# --------------------------------------------------------------------------

base64() {
   openssl base64 -e -A | tr -- '+/' '-_' | tr -d =
}

sign() {
   printf "$1"| openssl dgst -binary -sha256 -sign "$authKey" | base64
}

time=$(date +%s)
header=$(printf '{ "alg": "ES256", "kid": "%s" }' "$authKeyId" | base64)
claims=$(printf '{ "iss": "%s", "iat": %d }' "$teamId" "$time" | base64)
jwt="$header.$claims.$(sign $header.$claims)"

curl --verbose \
   --header "content-type: application/json" \
   --header "authorization: bearer $jwt" \
   --header "apns-topic: $bundleId" \
   --header "apns-priority: $priority" \
   --header "apns-push-type: $pushType" \
   --data "$payload" \
   $endpoint/3/device/$deviceToken
