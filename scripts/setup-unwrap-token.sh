#!/bin/bash

set -x

ADDRESS=$1
SHARED_DIR=$2
export VAULT_ADDR="http://${ADDRESS}:8200"
VAULT_TOKEN=$(cat /var/shared/autounseal.token) vault unwrap -format=json | jq -r '.auth.client_token' > ${SHARED_DIR}/autounseal.token.unwrapped

