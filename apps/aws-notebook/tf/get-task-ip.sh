#!/bin/bash
set -e
set -o pipefail

AWS_REGION=$(aws configure get region)


eval "$(echo $1 | jq -r '@sh "ECS_CLUSTER_NAME=\(.ecs_cluster_name) ECS_SERVICE_NAME=\(.ecs_service_name)"')"

function get_task_ip(){
  TASK_ARN=$(aws ecs list-tasks --region ${AWS_REGION} --cluster ${ECS_CLUSTER_NAME} --service=${ECS_SERVICE_NAME} | jq .taskArns[0] | tr -d '"')
  TASK_IP=$(aws ecs describe-tasks --tasks ${TASK_ARN} --region ${AWS_REGION} --cluster ${ECS_CLUSTER_NAME} | jq '.tasks[0].attachments[0].details[] | select(.name=="privateIPv4Address") | .value' |  tr -d '"')

  echo ${TASK_IP}
}

function get_stable_task_ip(){
  while true;do
    TASK_IP=$(get_task_ip)
    if [[ -z "${FINAL_TASK_IP}" ]];then
      FINAL_TASK_IP=${TASK_IP}
      sleep 2
      continue
    fi
    echo ${TASK_IP} >> /tmp/tmp.txt
    if [[ "$TASK_IP" == "${FINAL_TASK_IP}" ]];then
      FINAL_TASK_IP_COUNT=$(expr $FINAL_TASK_IP_COUNT + 1)
      if [[ $FINAL_TASK_IP_COUNT -ge 3 ]];then
        break
      fi
    else
      FINAL_TASK_IP=$TASK_IP
      FINAL_TASK_IP_COUNT=0
    fi
    sleep 2
  done
  echo ${TASK_IP}
}

TASK_IP=$(get_stable_task_ip)

echo {'"'private_ip'"':'"'${TASK_IP}'"'}
