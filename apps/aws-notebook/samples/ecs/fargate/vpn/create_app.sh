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

# Prepare snapshot
echo "🌸 Preparing snapshot for sandbox"
SNAPSHOT_NAME=${SNAPSHOT_NAME:-${APP_NAME}-base-notebook-v1}
cs app create ${APP_NAME}-sn -O ${SANDBOX_ORG} - << EOF
workspaces:
  - name: dev
    checkouts:
      - path: solutions
        repo:
          git: https://github.com/crafting-demo/solutions.git
EOF
set +e
cs sandbox create ${APP_NAME}-sn -a ${APP_NAME}-sn -O ${SANDBOX_ORG} 
if [[ $? -eq 0 ]];then
  SNAPSHOT_SANDBOX_CREATED="true"
else 
  ERROR="failed to create app to create base snapshot"
fi

if [[ -n "$SNAPSHOT_SANDBOX_CREATED" ]];then
  cs ssh -W ${APP_NAME}-sn/dev -O ${SANDBOX_ORG} -- chmod +x solutions/shared/snapshots/notebook/build_base.sh 
  cs ssh -W ${APP_NAME}-sn/dev -O ${SANDBOX_ORG} -- sudo solutions/shared/snapshots/notebook/build_base.sh ${SNAPSHOT_NAME} 
  [[ $? -eq 0 ]] || ERROR="failed to create snapshot"
fi

if [[ -n "$SNAPSHOT_SANDBOX_CREATED" ]];then
  cs sandbox delete ${APP_NAME}-sn -O ${SANDBOX_ORG} --force
  [[ $? -eq 0 ]] || ERROR="${ERROR}, failed to cleanup sandbox"
fi

cs app delete ${APP_NAME}-sn -O ${SANDBOX_ORG} --force
[[ $? -eq 0 ]] || ERROR="${ERROR}, failed to cleanup app"

[[ -z "$ERROR" ]] || fatal "${ERROR}, failed to create base snapshot"

set -e
# Upload OpenVPN Config
echo "🌸 Uploading OpenVPN Config"
cs secret create ${APP_NAME}-openvpn-config -O ${SANDBOX_ORG} --shared -f - << EOF
$(terraform output -raw client_config)
EOF


# Create app
echo "🌸 Creating App"
sed "s/AWS_CONFIG_FILE.*/AWS_CONFIG_FILE=\/run\/sandbox\/fs\/secrets\/shared\/${AWS_CONFIG}/g" ../../../../app.yaml | \
    sed "s/OPENVPN_CONFIG_FILE.*/OPENVPN_CONFIG_FILE=\/run\/sandbox\/fs\/secrets\/shared\/${APP_NAME}-openvpn-config/g" | \
    sed "s/ECS_CLUSTER_NAME.*/ECS_CLUSTER_NAME=${ECS_CLUSTER_NAME}/g" | \
    sed "s/SUBNET_ID.*/SUBNET_ID=${SUBNET_ID}/g" | \
    sed "s/SERVICE_LAUNCH_TYPE.*/SERVICE_LAUNCH_TYPE=${SERVICE_LAUNCH_TYPE}/g" | \
    sed  "s#TASK_IMAGE=.*#TASK_IMAGE=${TASK_IMAGE}#g" | \
    sed "s/base_snapshot.*/base_snapshot: ${SNAPSHOT_NAME}/g" | \
    cs app create ${APP_NAME} -O ${SANDBOX_ORG} -

echo "🎉 Notebook created, now you can create a sandbox with the app: cs sandbox create YOUR_SANDBOX_NAME -a ${APP_NAME}"  
