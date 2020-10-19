
# AWS CodeDeploy

This repo contains a cloudformation script to create resources ECS Service and CodeDeploy for Blue/Green deployment. You can look at the `ecs-service.cfn.yml` to see what are all the resources created.

This also contains a folder `one-time-per-aws-account` for creating following resources per each AWS account prod and nonprod 

1. An Health check Lambda
2. Placeholder ECR repo.

Please look at their respective documentation for help.

## Creating new ECS service and Code deploy resources

_**NOTE:**_ Please use the documentation in parent level `aws-dev-tools` to create CodeBuild, ECS Service and COdeDeploy resources for a freshly created apps. Use the below documentation only if you want to create ECS service for new env other than `dev | nonprod | prod`

1. If you are using Bayer `aws-sso`, you need to add  `--profile saml` for all the aws cli command in all the scripts in this repo.
2. The app needs to have `/ping` api available which should return 200 status code for the deployment to be successful. It is used for health check by target group.
3. Run `./create-service.sh <app-name>-<env>`. **Note** the `-<env>`. The `-<env>` should be other than `dev | nonprod | prod`.
4. **Reminding again:** Please use the documentation in parent level `aws-dev-tools` to create `dev | nonprod | prod` ECS resources and CodeBuild projects.

## Useful References

1. [YouTube 1](https://www.youtube.com/watch?edufilter=NULL&t=556s&v=5VPIzKDyLvo)
2. [YouTube 2](https://www.youtube.com/watch?edufilter=NULL&t=2s&v=ekh2uW1VU6U)