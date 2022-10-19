#!/bin/bash
set -e

GENERATED_BASE_DIR="generated"

[[ ! -d "easy-rsa" ]] && git clone https://github.com/OpenVPN/easy-rsa.git > /dev/null 2>&1
  

[[ ! -d "${GENERATED_BASE_DIR}" ]] && mkdir "$GENERATED_BASE_DIR"

if [[ ! -f "$GENERATED_BASE_DIR/generated_mark" ]];then
  # Generate keys and certs
  ORIGIN_WORKING_DIR=$(pwd)
  cd easy-rsa/easyrsa3 > /dev/null
  echo "yes" | ./easyrsa init-pki > /dev/null
  echo "craftingdemo" | ./easyrsa build-ca nopass > /dev/null 2>&1
  echo "yes" | ./easyrsa build-server-full notebook.server.crafting.demo nopass > /dev/null 2>&1
  echo "yes" | ./easyrsa build-client-full notebook.client.crafting.demo nopass > /dev/null 2>&1
  cp pki/ca.crt ../../${GENERATED_BASE_DIR}/
  cp pki/issued/notebook.server.crafting.demo.crt ../../${GENERATED_BASE_DIR}/
  cp pki/private/notebook.server.crafting.demo.key ../../${GENERATED_BASE_DIR}/
  cp pki/issued/notebook.client.crafting.demo.crt ../../${GENERATED_BASE_DIR}/
  cp pki/private/notebook.client.crafting.demo.key ../../${GENERATED_BASE_DIR}/
  cd $ORIGIN_WORKING_DIR
  touch $GENERATED_BASE_DIR/generated_mark
fi

cat << EOF
  {
    "ca_cert":"${GENERATED_BASE_DIR}/ca.crt",
    "server_cert":"${GENERATED_BASE_DIR}/notebook.server.crafting.demo.crt",
    "server_key":"${GENERATED_BASE_DIR}/notebook.server.crafting.demo.key",
    "client_cert":"${GENERATED_BASE_DIR}/notebook.client.crafting.demo.crt",
    "client_key":"${GENERATED_BASE_DIR}/notebook.client.crafting.demo.key"
  }
EOF


