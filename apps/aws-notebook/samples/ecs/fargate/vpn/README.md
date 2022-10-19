# Scripts to quicky deploy a aws-notebook  development environment
This will create a AWS ECS cluster and a aws-notebook sandbox app by some commands.

The only thing you need to prepare is a image for your ecs service. You should build it from this [dockerfile](https://github.com/crafting-demo/solutions/blob/master/apps/aws-notebook/image/Dockerfile) and push it to your aws container registry


## Usage
```bash
# Create AWS ECS
terraform init && terraform apply -auto-approve 

# Create a sandbox app for aws-notebook
## Export AWS config
export AWS_REGION=xxxx
export AWS_ACCESS_KEY_ID=xxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxx
export AWS_SESSION_TOKEN=xxxxx
# The prepared task image for ecs task container, you should build it from this dockerfile:https://github.com/crafting-demo/solutions/blob/master/apps/aws-notebook/image/Dockerfile and push it to your aws container registry
export TASK_IMAGE=xxxx
./create_app.sh ${YOUR_APP_NAME}
# instance a sandbox  from the app
cs  sandbox create ${YOUR_SANDBOX_NAME} -a ${YOUR_APP_NAME}
```

## Clean the resources
``` bash
# Delete the resources in sandbox
cs sandbxo delete ${YOUR_SANDBOX_NAME}
cs app delete ${YOUR_APP_NAME}
cs  secret delete ${YOUR_APP_NAME}-aws-config
cs  secret delete ${YOUR_APP_NAME}-openvpn-config

# Delete the resouces in AWS
terraform destroy -auto-approve
```

## FAQ
* The AWS Token expired will result to the sandbox failed to create ecs service task. Please update the secret of aws-config for your app
