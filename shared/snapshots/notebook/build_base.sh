#!/bin/bash

set -ex

function fatal() {
    echo "$@" >&2
    exit 1
}

[[ "$(id -u)" == "0" ]] || fatal "Must run as root!"

if [[ -z "$1" ]];then
  echo "Please provide a snaptshot name. For eaxmaple: ./build_bash.sh base-notebook-v1"
fi

apt-get update
apt-get install -y openvpn jq
curl -sSLf https://releases.hashicorp.com/terraform/1.2.8/terraform_1.2.8_linux_amd64.zip | funzip >/usr/local/bin/terraform
chmod a+rx /usr/local/bin/terraform
curl -sSLf -o /tmp/awscli.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -d /tmp -o /tmp/awscli.zip
/tmp/aws/install
cs snapshot create "$1"
