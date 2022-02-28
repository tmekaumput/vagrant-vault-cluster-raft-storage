#!/usr/bin/env bash
set -x


vault_systemd () {

if sudo test ! -f ${1}/vault.service; then

sudo bash -c "cat >${1}/vault.service" << 'EOF'
[Unit]
Description=Vault Agent

[Service]
Restart=on-failure
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/bin/vault
ExecStart=/usr/bin/vault server -config /etc/vault.d/vault.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=vault
Group=vault

[Install]
WantedBy=multi-user.target
EOF

else

  echo "Systemd file, ${1}/vault.service, already exists"
fi

}

SYSTEMD_DIR="/etc/systemd/system"
echo "Installing systemd services for RHEL/CentOS"

vault_systemd ${SYSTEMD_DIR}
sudo chmod 0664 ${SYSTEMD_DIR}/vault*

