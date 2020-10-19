# AWS Dev tools

This folder contains the infra setup scripts needed to create AWS CodeBuild, AWS CodeDeploy, ECS service and it's target/security groups for a newly added repo in GitHub

## Pre-requisites

1. Install the [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. Create a personal access token for GitHub Enterprise as shown [HERE](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line). It needs the following permissions
   - repo
   - admin:repo_hook
3. Create a `.secrets` file at the root level of `aws-dev-tools` repo (**Not** in `code-build` folder) and add the below content.

```
export GHE_ACCESS_TOKEN=<Github Personal access token here>
```

## To create all the above resources

1. Login via `aws-sso`.
2. Simply run the below script by cd into this folder and wait for all the resources creation.

_**NOTE:**_ If you are using Bayer `aws-sso`, you need to add  `--profile saml` for all the aws cli command in all the scripts in this repo.

```
./create-resources.sh \
    AppName="<github-repo-name>" \
    IsDevEnvNeeded="<yes | no>" \
    RunTime="<nodejs | scala>" \
    Platform="<ecs | lambda>"
```

Example

```
./create-resources.sh \
    AppName="assets-kafka-consumer" \
    IsDevEnvNeeded="yes" \
    RunTime="nodejs" \
    Platform="ecs"
```

After all the resources are created, you need to follow the Readme.md in `code-build` folder for instruction on creating `deploy.sh` file in the project.

## Clean ups

1. **CodeBuild:**
    - Delete the `<app-name>-code-build-project` cloudformation stacks in both prod and nonprod AWS Console.
    - Delete the `webhooks` in Github for the repo
2. **CodeDeploy:**
    - Delete the `<app-name>-ecs-service` cloudformation stacks in both prod and nonprod AWS Console.
    - Delete the `<app-name>-dev-ecs-service`, if `dev` env exists in nonprod AWS.
    - The cloudformation deletion fails, if App ECR repo has a docker image pushed since stack creation. You can skip ECR repo in 2nd attempt of stack deletion. Then, you need to manually delete the app ECR repo.
