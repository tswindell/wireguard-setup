#! /bin/bash

if [ -z "$1" ]; then
  echo "You must supply a filepath prefix for the key pair."
  exit 1
fi

wg genkey | tee "${1}.key" | wg pubkey > "${1}.pub"