# Script to quicky deploy a aws-notebook  development environment

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
cs create sandbox ${YOUR_SANDBOX_NAME} -a ${YOUR_APP_NAME}
```
