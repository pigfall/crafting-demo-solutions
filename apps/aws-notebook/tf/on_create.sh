#!/bin/bash

set -ex
set -o pipefail

# Prepare key-pair used to connect to ecs container
rm -f ~/.ssh/aws-notebook_rsa
rm -f ~/.ssh/aws-notebook_rsa.pub
ssh-keygen -t rsa -N "" -f ~/.ssh/aws-notebook_rsa
SSH_PUBLIC_KEY=$(cat ~/.ssh/aws-notebook_rsa.pub)

terraform init 
terraform apply -auto-approve \
  -var="ecs_cluster_name=${ECS_CLUSTER_NAME}" \
  -var="subnet_id=${SUBNET_ID}" \
  -var="security_groups=${SECURITY_GROUPS}" \
  -var="ssh_public_key=${SSH_PUBLIC_KEY}" \
  -var="service_launch_type=${SERVICE_LAUNCH_TYPE}" \
  -var="task_image=${TASK_IMAGE}"


while true;do
  TASK_IP=$(./get-task-ip.sh)
  if [[ -z "${FINAL_TASK_IP}" ]];then
    FINAL_TASK_IP=${TASK_IP}
    sleep 2
    continue
  fi
  if [[ "$TASK_IP"=="${FINAL_TASK_IP}" ]];then
     FINAL_TASK_IP_COUNT=$(expr $FINAL_TASK_IP_COUNT + 1)
     if [[ $FINAL_TASK_IP_COUNT -ge 3 ]];then
       break
     fi
  else
    FINAL_TASK_IP_COUNT=$TASK_IP
    FINAL_TASK_IP_COUNT=0
  fi
  sleep 2
done

mkdir -p ~/.aws-notebook
echo ${FINAL_TASK_IP} > ~/.aws-notebook/ip.txt
