#!/bin/bash

set -e

[[ -z "${AWS_ACCESS_KEY_ID}" ]] && echo "AWS_ACCESS_KEY_ID is nil" 1>&2 && exit 1

[[ -z "${AWS_SECRET_ACCESS_KEY}" ]] && echo "AWS_SECRET_ACCESS_KEY is nil" 1>&2 && exit 1
[[ -z "${AWS_SESSION_TOKEN}" ]] && echo "AWS_SESSION_TOKEN is nil" 1>&2 && exit 1
[[ -z "${AWS_REGION}" ]] && echo "AWS_REGION is nil" 1>&2 && exit 1
[[ -z "${TASK_IMAGE}" ]] && echo "TASK_IMAGE is nil, please provide the url of notebook image,you could build it from this dockerfile:https://github.com/crafting-demo/solutions/blob/master/apps/aws-notebook/image/Dockerfile and push it to your aws container registry" 1>&2 && exit 1
[[ -z "${CRAFTING_ORG}" ]] && echo "CRAFTING_ORG is nil, please provide crafting orignization name" 1>&2 && exit 1


[[ $# -lt 1 ]] && echo "Missing APP_NAME. Usage: create_app.sh APP_NAME" && exit 1


APP_NAME="$1"
ECS_CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SUBNET_ID=$(terraform output -raw subnet_id)
SERVICE_LAUNCH_TYPE=$(terraform output -raw service_launch_type)
SECURITY_GROUP=$(terraform output -raw security_group)

# Prepare snapshot
echo "🌸 Preparing snapshot for sandbox"
cs app create tmpdemo-notebook -O ${CRAFTING_ORG} - << EOF
workspaces:
  - name: dev
    checkouts:
      - path: solutions
        repo:
          git: https://github.com/crafting-demo/solutions.git
        version_spec: master

EOF
cs sandbox create tmpdemo-notebook -a tmpdemo-notebook -O ${CRAFTING_ORG}
cs ssh -W tmpdemo-notebook/dev -O ${CRAFTING_ORG} bash -c "cd solutions/shared/snapshots/notebook/ && bash build_base.sh base-notebook-v1"
cs sandbox delete tmpdemo-notebook -O ${CRAFTING_ORG} --force
cs app delete tmpdemo-notebook -O ${CRAFTING_ORG} --force

# Upload AWS Config
echo "🌸 Uploading AWS Config"
cs secret create ${APP_NAME}-aws-config -O ${CRAFTING_ORG} --shared -f - << EOF
[default]
region=${AWS_REGION}
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
aws_session_token=${AWS_SESSION_TOKEN}
EOF

# Upload OpenVPN Config
echo "🌸 Uploading OpenVPN Config"
cs secret create ${APP_NAME}-openvpn-config -O ${CRAFTING_ORG} --shared -f ./generated/vpn_client_config.ovpn


# Create app
echo "🌸 Creating App"
sed "s/AWS_CONFIG_FILE.*/AWS_CONFIG_FILE=\/run\/sandbox\/fs\/secrets\/shared\/${APP_NAME}-aws-config/g" ../../../../app.yaml | \
    sed "s/OPENVPN_CONFIG_FILE.*/OPENVPN_CONFIG_FILE=\/run\/sandbox\/fs\/secrets\/shared\/${APP_NAME}-openvpn-config/g" | \
    sed "s/ECS_CLUSTER_NAME.*/ECS_CLUSTER_NAME=${ECS_CLUSTER_NAME}/g" | \
    sed "s/SUBNET_ID.*/SUBNET_ID=${SUBNET_ID}/g" | \
    sed "s/SERVICE_LAUNCH_TYPE.*/SERVICE_LAUNCH_TYPE=${SERVICE_LAUNCH_TYPE}/g" | \
    sed  "s#TASK_IMAGE=.*#TASK_IMAGE=${TASK_IMAGE}#g" | \
    sed "s/SECURITY_GROUPS=.*/SECURITY_GROUPS=${SECURITY_GROUP}/g" | \
    cs app create ${APP_NAME} -O ${CRAFTING_ORG} -

echo "🎉 Notebook created, now you can create a sandbox with the app: cs sandbox create YOUR_SANDBOX_NAME -a ${APP_NAME}"  
