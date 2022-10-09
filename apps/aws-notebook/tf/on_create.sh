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
