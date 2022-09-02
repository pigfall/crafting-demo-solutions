#!/bin/bash

function fatal() {
    echo "$@" >&2
    exit 1
}

[[ "$(id -u)" == "0" ]] || fatal "Must run as root!"

curl -sSLf https://dl.k8s.io/v1.20.5/kubernetes-client-linux-amd64.tar.gz | tar -C /usr/local/bin -zx --strip-components=3
curl -sSLf https://releases.hashicorp.com/terraform/1.2.8/terraform_1.2.8_linux_amd64.zip | funzip >/usr/local/bin/terraform
chmod a+rx /usr/local/bin/terraform
curl -sSLf https://get.helm.sh/helm-v3.9.4-linux-amd64.tar.gz | tar -C /usr/local/bin -zx --strip-components=1 --exclude='LICENSE*' --exclude='README*' --no-same-owner
curl -sSLf -o /usr/local/bin/direnv https://github.com/direnv/direnv/releases/download/v2.28.0/direnv.linux-amd64
chmod a+rx /usr/local/bin/direnv
curl -sSLf -o /tmp/awscli.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -d /tmp -o /tmp/awscli.zip
/tmp/aws/install
curl -sSLf https://raw.githubusercontent.com/rockymadden/slack-cli/v0.18.0/src/slack >/usr/local/bin/slack
chmod a+rx /usr/local/bin/slack
curl -sSLf https://github.com/bronze1man/yaml2json/releases/download/v1.3/yaml2json_linux_amd64 >/usr/local/bin/yaml2json
chmod a+rx /usr/local/bin/yaml2json
curl -sSLf https://github.com/bronze1man/json2yaml/releases/download/1.0/json2yaml_linux_amd64 >/usr/local/bin/json2yaml
chmod a+rx /usr/local/bin/json2yaml
