#!/usr/bin/env bash
set -x

SHARED_DIR=$1

INITIALIZED=$(vault status -format=json | jq -r '.initialized')

if [[ "${INITIALIZED}" == "false" ]]; then

  INIT_RESPONSE=$(vault operator init -format=json -key-shares 1 -key-threshold 1)

  UNSEAL_KEY=$(echo "$INIT_RESPONSE" | jq -r .unseal_keys_b64[0])
  VAULT_TOKEN=$(echo "$INIT_RESPONSE" | jq -r .root_token)

  sudo tee ${SHARED_DIR}/recovery_key-vault <<EOF
$RECOVERY_KEY
EOF

  sudo tee ${SHARED_DIR}/root_token-vault <<EOF
$VAULT_TOKEN
EOF

  sudo chown vault:vault ${SHARED_DIR}/recovery_key-vault
  sudo chown vault:vault ${SHARED_DIR}/root_token-vault

  printf "\n%s" \
    "[vault] Unseal key: $UNSEAL_KEY" \
    "[vault] Root token: $VAULT_TOKEN" \
    ""

  printf "\n%s" \
    "[vault] unsealing and logging in" \
    ""

  sleep 2s # Added for human readability

  vault operator unseal "$UNSEAL_KEY"
  vault login "$VAULT_TOKEN"

  printf "\n%s" \
    "[vault] enabling the transit secret engine and creating a key to auto-unseal vault cluster" \
    ""
  sleep 5s # Added for human readability

  vault secrets enable transit
  vault write -f transit/keys/unseal_key

  cat <<EOF > autounseal.hcl
path "transit/encrypt/unseal_key" {
   capabilities = [ "update" ]
}

path "transit/decrypt/unseal_key" {
   capabilities = [ "update" ]
}

EOF

  vault policy write autounseal autounseal.hcl
  vault token create -policy="autounseal" -wrap-ttl=3600 -format=json | jq -r '.wrap_info.token' > ${SHARED_DIR}/autounseal.token

else

  UNSEAL_KEY=$(cat ${SHARED_DIR}/transit/unseal_key-vault) vault operator unseal "$UNSEAL_KEY"

fi
