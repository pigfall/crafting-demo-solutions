#!/bin/bash

set -e

function fatal(){
  echo "$@" >&2
  exit 1
}

[[ -n "${TASK_IMAGE}" ]] || fatal "TASK_IMAGE is nil, please provide the url of container image,you could build it from this Dockerfile:https://github.com/crafting-demo/solutions/blob/master/apps/aws-notebook/image/Dockerfile and push it to ECR" 
[[ -n "${SANDBOX_ORG}" ]] || fatal "SANDBOX_ORG is nil, please provide sandbox organization name"
[[ -n "${AWS_CONFIG}" ]] || fatal "AWS_CONFIG is nil, please provide the secret name of your AWS config"


APP_NAME="$1"
[[ -n "$APP_NAME" ]] || fatal "Missing APP_NAME. Usage: create_app.sh APP_NAME"


ECS_CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SUBNET_ID=$(terraform output -raw subnet_id)
SERVICE_LAUNCH_TYPE=$(terraform output -raw service_launch_type)
SECURITY_GROUP=$(terraform output -raw security_group)

# Prepare snapshot
echo "🌸 Preparing snapshot for sandbox"
cs app create tmpdemo-notebook -O ${SANDBOX_ORG} - << EOF
workspaces:
  - name: dev
    checkouts:
      - path: solutions
        repo:
          git: https://github.com/crafting-demo/solutions.git
        version_spec: master

EOF
cs sandbox create tmpdemo-notebook -a tmpdemo-notebook -O ${SANDBOX_ORG}
cs ssh -W tmpdemo-notebook/dev -O ${SANDBOX_ORG} bash -c "cd solutions/shared/snapshots/notebook/ && bash build_base.sh base-notebook-v1"
cs sandbox delete tmpdemo-notebook -O ${SANDBOX_ORG} --force
cs app delete tmpdemo-notebook -O ${SANDBOX_ORG} --force

# Upload OpenVPN Config
echo "🌸 Uploading OpenVPN Config"
cs secret create ${APP_NAME}-openvpn-config -O ${SANDBOX_ORG} --shared -f ./generated/vpn_client_config.ovpn


# Create app
echo "🌸 Creating App"
sed "s/AWS_CONFIG_FILE.*/AWS_CONFIG_FILE=\/run\/sandbox\/fs\/secrets\/shared\/${AWS_CONFIG}/g" ../../../../app.yaml | \
    sed "s/OPENVPN_CONFIG_FILE.*/OPENVPN_CONFIG_FILE=\/run\/sandbox\/fs\/secrets\/shared\/${APP_NAME}-openvpn-config/g" | \
    sed "s/ECS_CLUSTER_NAME.*/ECS_CLUSTER_NAME=${ECS_CLUSTER_NAME}/g" | \
    sed "s/SUBNET_ID.*/SUBNET_ID=${SUBNET_ID}/g" | \
    sed "s/SERVICE_LAUNCH_TYPE.*/SERVICE_LAUNCH_TYPE=${SERVICE_LAUNCH_TYPE}/g" | \
    sed  "s#TASK_IMAGE=.*#TASK_IMAGE=${TASK_IMAGE}#g" | \
    sed "s/SECURITY_GROUPS=.*/SECURITY_GROUPS=${SECURITY_GROUP}/g" | \
    cs app create ${APP_NAME} -O ${SANDBOX_ORG} -

echo "🎉 Notebook created, now you can create a sandbox with the app: cs sandbox create YOUR_SANDBOX_NAME -a ${APP_NAME}"  
