# ECR Place holder

This folder contains the files required to build a docker image that will be used pushed to AWS ECR as a `placeholder` repo. The ECR `placeholder` image will be used whenever a new ECS service is created for a new project/app. The new project's docker image won't be pushed to ECR without creating the repo. And can not be deployed until an ECS service is created. The ECR repo and ECS Service are created by following the instruction in `code-deploy` folder. But, to create a service and run a container there should be an image exist in the ECR. As the new Project is not yet pushed to ECR, we will use this simple node.js app image as a placeholder. After the service and it's component (target groups, security groups, listener rules, code deploy app etc,...) are created, the first project deployment will replace this placeholder container with original project's container in ECS service.

## Notes

Create the repo using the `create-repo.sh`, which will create the repo in both prod and nonprod AWS ECR.
Login to AWS CLI using `aws-sso`.
The `Docker` file is already included. So just make a docker image out of it and use instructions in `placeholder` ECR repo to push the image. Onetime only.
