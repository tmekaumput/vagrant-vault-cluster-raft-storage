#!/usr/bin/env bash
set -x

USER="${1}"
COMMENT="Hashicorp ${1} user"
GROUP="${1}"
HOME="/home/${1}"

echo "Setting up user ${USER}"
sudo /usr/sbin/groupadd --force --system ${GROUP}

if ! getent passwd ${USER} >/dev/null ; then
  sudo /usr/sbin/adduser \
    --system \
    --gid ${GROUP} \
    --home ${HOME} \
    --comment "${COMMENT}" \
    --shell /bin/bash \
    ${USER}  >/dev/null
fi


