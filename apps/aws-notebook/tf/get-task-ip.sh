#!/bin/bash
set -e

AWS_REGION=$(aws configure get region)

TASK_ARN=$(aws ecs list-tasks --region ${AWS_REGION} --cluster ${ECS_CLUSTER_NAME} --service=notebook_${SANDBOX_ID} | jq .taskArns[0] | tr -d '"')
TASK_IP=$(aws ecs describe-tasks --tasks ${TASK_ARN} --region ${AWS_REGION} --cluster ${ECS_CLUSTER_NAME} | jq '.tasks[0].attachments[0].details[] | select(.name=="privateIPv4Address") | .value' |  tr -d '"')

echo {'"'task_private_ip'"':${TASK_IP}}
