# Pre Traffic Hook Lambda

A lambda function to check container health whenever a new green deployment is happening in CodeDeploy Blue/Green deployment for ECS.

The CodeDeploy will spin up a new container in the respective ECS service (called green resource). There are various [Life cycle hooks](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html) in CodeDeploy where we can invoke lambdas at each hook.

This Lambda function is triggered at `BeforeAllowTraffic`. It calls URL of the corresponding app `http://<app-name>.<aws-account-id>.internal.monsanto.net/ping` to check for newly spun up container health. Note, the `http` here. So this request will be forwarded to HTTP, TEST LISTENER, on PORT 80 that we configured in our AWS Application Load Balancer. This Test Listener is used by CodeDeploy initially to test/validate the traffic, before re-routing the prod traffic to new container from Prod Listener which is configured on PORT 443 for HTTPs.

If the health check URL returns a status code `200`, the Lambda will notify back the CodeDeploy that the traffic is good on new container app. Then the CodeDeploy will proceed to re-route the prod traffic to new container and kill the old container. Otherwise, it will roll back and keep the old container, by destroying the newly spun up app container.

## Note

This Lambda is created one time per AWS account. To create the lambda in AWS simply run the `create-lambda.sh`.

There are couple of things to do after creating the Lambda

1. Attach the `AWSCodeDeployFullAccess` Policy to `kpi-automation-lambda` role, so it can read/write the deployment config and hook success/failure details in both AWS environments.
2. Add the security group created from cloudformation `CodeDeploy pre-traffic lambda hook`, in our ALB security group inbound rules for `HTTP` traffic, in both AWS environments.
