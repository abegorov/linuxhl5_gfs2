#!/bin/sh
set -eu
HOST="${1}"
ANSIBLE_HOST=$(yq .[].hosts inventory.yml | yq .${HOST}.ansible_host)
SSH_USER=$(yq ".[] | select(.hosts | has(\"${HOST}\")) |
  .vars.ansible_user" inventory.yml)
SSH_KEY=$(yq ".[] | select(.hosts | has(\"${HOST}\")) |
  .vars.ansible_ssh_private_key_file" inventory.yml)
SSH_ARGS=$(yq ".[] | select(.hosts | has(\"${HOST}\")) |
  .vars.ansible_ssh_common_args" inventory.yml |
  sed 's/ -o ControlMaster=auto -o ControlPersist=600s//')
eval ssh ${SSH_ARGS} \
  -i \'"${SSH_KEY}"\' -l \'"${SSH_USER}"\' \'"${ANSIBLE_HOST}"\'
