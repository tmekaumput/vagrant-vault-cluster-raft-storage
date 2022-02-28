#!/usr/bin/env bash
set -x

NODE_ID="$1"
ADDRESS="$2"
TRANSIT_NODE_ID="$3"
LEADER_NODE_ID="$4"

if [[ "${NODE_ID}" != "${TRANSIT_NODE_ID}" ]]; then
  export TRANSIT_NODE_ADDRESS=$5
  if [[ "${NODE_ID}" != "${LEADER_NODE_ID}" ]]; then
    export LEADER_API_ADDRESS="$6"
    #LEADER_API_ADDRESSES="$6"
  fi
fi

UNSEAL_TOKEN=$(sudo cat /var/shared/autounseal.token.unwrapped)
DATA_DIR="/var/data/raft-vault"

export NODE_ID DATA_DIR ADDRESS TRANSIT_NODE_ID

function config_cluster_leader_node {

  rm -f vault.hcl

  sudo cp /tmp/license.txt /etc/vault.d/license.txt

  cat <<-EOF > vault.hcl

  license_path = "/etc/vault.d/license.txt"
  storage "raft" {
    path    = "${DATA_DIR}"
    node_id = "vault_${NODE_ID}"
  }
  listener "tcp" {
    address     = "0.0.0.0:8200"
    cluster_address = "${ADDRESS}:8201"
    tls_disable = 1
  }
  seal "transit" {
    address            = "http://${TRANSIT_NODE_ADDRESS}:8200"
    token              = "${UNSEAL_TOKEN}"
    disable_renewal    = "false"

    // Key configuration
    key_name           = "unseal_key"
    mount_path         = "transit/"
  }
  ui=true
  disable_mlock = true
  api_addr = "http://${ADDRESS}:8200"
  cluster_addr = "http://${ADDRESS}:8201"
EOF

  sudo mkdir -p "${DATA_DIR}"
  sudo chown -R vault:vault "${DATA_DIR}"
}

function config_cluster_follower_node {

  rm -f vault.hcl

  sudo cp /tmp/license.txt /etc/vault.d/license.txt

  cat <<-EOF > vault.hcl

  license_path = "/etc/vault.d/license.txt"
  storage "raft" {
    path    = "${DATA_DIR}"
    node_id = "vault_${NODE_ID}"

    #for LEADER_API_ADDRESS in "${LEADER_API_ADDRESSES[@]}"
    #do

    retry_join {
      leader_api_addr = "${LEADER_API_ADDRESS}"
    }

    #done
  }
  listener "tcp" {
    address     = "0.0.0.0:8200"
    cluster_address = "${ADDRESS}:8201"
    tls_disable = 1
  }
  seal "transit" {
    address            = "http://${TRANSIT_NODE_ADDRESS}:8200"
    token              = "${UNSEAL_TOKEN}"
    disable_renewal    = "false"

    // Key configuration
    key_name           = "unseal_key"
    mount_path         = "transit/"
  }
  ui=true
  disable_mlock = true
  api_addr = "http://${ADDRESS}:8200"
  cluster_addr = "http://${ADDRESS}:8201"
EOF

  sudo mkdir -p "${DATA_DIR}"
  sudo chown -R vault:vault "${DATA_DIR}"

}


function config_transit_node {

  rm -f vault.hcl

  sudo cp /tmp/license.txt /etc/vault.d/license.txt

  cat <<-EOF > vault.hcl
    license_path = "/etc/vault.d/license.txt"
    storage "inmem" {}
    listener "tcp" {
      address = "${ADDRESS}:8200"
      tls_disable = true
    }
    disable_mlock = true
EOF

}

sudo mkdir -p /etc/vault.d

if [[ "${NODE_ID}" == "${TRANSIT_NODE_ID}" ]]; then
    config_transit_node
elif [[ "${NODE_ID}" == "${LEADER_NODE_ID}" ]]; then
    config_cluster_leader_node
else
    config_cluster_follower_node
fi

sudo mv vault.hcl /etc/vault.d/
sudo chown -R vault:vault /etc/vault.d /etc/ssl/vault
sudo chmod -R 0644 /etc/vault.d/*
