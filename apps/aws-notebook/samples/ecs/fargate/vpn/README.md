# Scripts to quicky deploy a aws-notebook  development environment

This will create an AWS ECS cluster and an [aws-notebook sandbox app](https://github.com/crafting-demo/solutions/blob/master/apps/aws-notebook/app.yaml).

# Prerequisites

- Build a container image to be used by the ECS service. Use this [Dockerfile](https://github.com/crafting-demo/solutions/blob/master/apps/aws-notebook/image/Dockerfile) as reference and push to ECR.

- Upload your AWS config to sandbox secrets. For example:
  - If you use this repo in sandbox env, We recommend you use the Identity federation to prevent the AWS credential expiration.
    ```sh
    cs secret create <YOUR_AWS_CONFIG> --shared -f - << EOF
    [default]
    region = <REGION>
    credential_process = idfed aws <ACCOUNT-ID> <ROLE>
    EOF
    ```
  - Or using AWS credentials
    ```sh
    cs secret create ${YOUR_AWS_CONFIG} --shared -f - << EOF
    [default]
    region= <AWS_REGION>
    aws_access_key_id= <AWS_ACCESS_KEY_ID>
    aws_secret_access_key= <AWS_SECRET_ACCESS_KEY>
    aws_session_token= <AWS_SESSION_TOKEN>
    EOF
    ```

## Usage

```sh
# Create AWS ECS
terraform init && terraform apply -auto-approve 

# Create a sandbox app for aws-notebook
# The prepared AWS config
export AWS_CONFIG=<YOUR_AWS_CONFIG>
# The prepared container image for ECS task service.
export TASK_IMAGE=<TASK_IMAGE>
# Which sandbox organization will be used to create the app
export SANDBOX_ORG=<SANDBOX_ORG>
./create_app.sh <YOUR_APP_NAME>
# instance a sandbox  from the app
cs  sandbox create <YOUR_SANDBOX_NAME> -a <YOUR_APP_NAME>
```

## Clean the resources
``` bash
# Delete the resources in sandbox
cs sandbxo delete <YOUR_SANDBOX_NAME>
cs app delete <YOUR_APP_NAME>
cs secret delete <YOUR_APP_NAME>-openvpn-config

# Delete the resouces in AWS
terraform destroy -auto-approve
```

## FAQ
* If you use the AWS credentials, the AWS token expiration will result to the sandbox failed to create ecs service task. Please update the secret of aws-config for your app. We recommend you use Identity federation  in sandbox env to prevent this situation.
