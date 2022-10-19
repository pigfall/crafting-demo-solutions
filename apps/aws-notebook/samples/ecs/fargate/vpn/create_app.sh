#!/bin/bash

set -e

[[ -z "${AWS_ACCESS_KEY_ID}" ]] && echo "AWS_ACCESS_KEY_ID is nil" 1>&2 && exit 1

[[ -z "${AWS_SECRET_ACCESS_KEY}" ]] && echo "AWS_SECRET_ACCESS_KEY is nil" 1>&2 && exit 1
[[ -z "${AWS_SESSION_TOKEN}" ]] && echo "AWS_SESSION_TOKEN is nil" 1>&2 && exit 1
[[ -z "${AWS_REGION}" ]] && echo "AWS_REGION is nil" 1>&2 && exit 1
[[ -z "${TASK_IMAGE}" ]] && echo "TASK_IMAGE is nil, please provide the url of notebook image" 1>&2 && exit 1


[[ $# -lt 1 ]] && echo "Missing APP_NAME. Usage: create_app.sh APP_NAME" && exit 1


APP_NAME="$1"
ECS_CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SUBNET_ID=$(terraform output -raw subnet_id)
SERVICE_LAUNCH_TYPE=$(terraform output -raw service_launch_type)
SECURITY_GROUP=$(terraform output -raw security_group)

# Upload AWS Config
cs secret create ${APP_NAME}-aws-config --shared -f - << EOF
[default]
aws_region=${AWS_REGION}
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
aws_session_token=${AWS_SESSION_TOKEN}
EOF

# Upload OpenVPN Config
cs secret create ${APP_NAME}-openvpn-config --shared -f ./generated/vpn_client_config.ovpn

# Create app
sed "s/AWS_CONFIG_FILE.*/AWS_CONFIG_FILE=\/run\/sandbox\/fs\/secrets\/shared\/${APP_NAME}-aws-config/g" ../../../../app.yaml | \
    sed "s/OPENVPN_CONFIG_FILE.*/OPENVPN_CONFIG_FILE=\/run\/sandbox\/fs\/secrets\/shared\/${APP_NAME}-openvpn-config/g" | \
    sed "s/ECS_CLUSTER_NAME.*/ECS_CLUSTER_NAME=${ECS_CLUSTER_NAME}/g" | \
    sed "s/SUBNET_ID.*/SUBNET_ID=${SUBNET_ID}/g" | \
    sed "s/SERVICE_LAUNCH_TYPE.*/SERVICE_LAUNCH_TYPE=${SERVICE_LAUNCH_TYPE}/g" | \
    sed "s/TASK_IMAGE=.*/TASK_IMAGE=${TASK_IMAGE}/g" | \
    sed "s/SECURITY_GROUPS=.*/SECURITY_GROUPS=${SECURITY_GROUP}/g" | \
    cs app create ${APP_NAME} -
