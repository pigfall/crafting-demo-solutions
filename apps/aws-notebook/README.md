# Application For Jupter Notebook

## Parameter In Environment Variables
- `AWS_CONFIG_FILE`: required, the path to config file for AWS CLI stored as a secret;
- `OPENVPN_CONFIG_FILE`: required, the path to the OpenVPN config file stored as a secret to connect to the private VPC;
- `ECS_CLUSTER`: required, the name of the ECS cluster;
- `SUBNET_ID`: required, the subnet to create ECS tasks;
- `SERVICE_LAUNCH_TYPE`: required, `FARGATE` or `EC2`;
- `TASK_IMAGE`: required, the image of ECS task
- `SECURITY_GROUPS`: optional, the security_groups of ECS task, default value is the default security_groups of VPC the subnet id belongs to
