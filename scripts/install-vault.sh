#!/usr/bin/env bash
set -x

HOST_ADDRESS=$1
SHARED_DIR=$2

if sudo test -f ${VAULT_DEST_DIR}/vault; then
  echo "Vault executable file already exists, skipping"
  exit 0
fi

RELEASE_SERVER="releases.hashicorp.com"
VAULT_LATEST_VERSION="$(curl -s https://releases.hashicorp.com/vault/index.json | jq -r '.versions[].version' | grep -v 'beta\|rc' | tail -n 1)"
VAULT_FILENAME="vault_${VAULT_LATEST_VERSION}_linux_amd64.zip"
VAULT_SHASUM_FILENAME="vault_${VAULT_LATEST_VERSION}_SHA256SUMS"
VAULT_DEST_DIR="/usr/bin"
VAULT_SHASUM_DOWNLOAD_URL=${URL:-"https://${RELEASE_SERVER}/vault/${VAULT_LATEST_VERSION}/${VAULT_SHASUM_FILENAME}"}

if [[ ! -f "${SHARED_DIR}/${VAULT_FILENAME}" ]]; then

  VAULT_DOWNLOAD_URL=${URL:-"https://${RELEASE_SERVER}/vault/${VAULT_LATEST_VERSION}/${VAULT_FILENAME}"}
  echo "Retrieving vault version: ${VAULT_LATEST_VERSION}"
  sudo curl --silent --output "${SHARED_DIR}/${VAULT_FILENAME}" ${VAULT_DOWNLOAD_URL}

else

  echo "Using existing installer from ${SHARED_DIR}/${VAULT_FILENAME}"

fi

echo "Retrieving vault checksum: ${VAULT_SHASUM_FILENAME}"
curl --silent --output /tmp/${VAULT_SHASUM_FILENAME} ${VAULT_SHASUM_DOWNLOAD_URL}

SHASUM1=$(cat /tmp/${VAULT_SHASUM_FILENAME} | awk '{print $1}')
SHASUM2=$(sha256sum ${SHARED_DIR}/${VAULT_FILENAME} | awk '{print $1}')

if [[ "${SHASUM1}" != "${SHASUM2}" ]]; then
   echo "Failed checksum, expected ${SHASUM1}, but getting ${SHASUM2}"
   exit -1
fi
echo "Installing vault"
sudo unzip -o ${SHARED_DIR}/${VAULT_FILENAME} -d ${VAULT_DEST_DIR}
sudo chmod 0755 ${VAULT_DEST_DIR}/vault
sudo chown vault:vault ${VAULT_DEST_DIR}/vault
sudo mkdir -pm 0755 /etc/vault.d
sudo mkdir -pm 0755 /etc/ssl/vault

echo "${VAULT_DEST_DIR}/vault --version: $(${VAULT_DEST_DIR}/vault --version)"

sudo chown -R vault:vault /etc/vault.d /etc/ssl/vault
sudo chmod -R 0644 /etc/vault.d/*
echo "export VAULT_ADDR=http://${HOST_ADDRESS}:8200" | sudo tee /etc/profile.d/vault.sh

