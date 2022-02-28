#!/bin/bash

set -x

ADDRESS=$1
SHARED_DIR=$2

if sudo test -f ${SHARED_DIR}/autounseal.token; then
  if sudo test -f ${SHARED_DIR}/autounseal.token.unwrapped; then
    echo "Auto-unseal token already exists"
    exit 0
  fi 
fi 

export VAULT_ADDR="http://${ADDRESS}:8200"
VAULT_TOKEN=$(sudo cat /var/shared/autounseal.token) vault unwrap -format=json | jq -r '.auth.client_token' > /tmp/autounseal.token.unwrapped
sudo mv /tmp/autounseal.token.unwrapped ${SHARED_DIR}/autounseal.token.unwrapped
sudo chown vault:vault ${SHARED_DIR}/autounseal.token.unwrapped

