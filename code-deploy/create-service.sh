#!/bin/bash
set -e

APP_NAME=$1

if  [ "$AWS_PROFILE" = "103299287643/standard-user" ]; then
  AWS_ENVIRONMENT="nonprod"
  AWS_ACCOUNT_ID=""
  FARGATE_STACK_NAME=""
  LOAD_BALANCER="SC-10-...."
  PROD_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:12344343:listener/app/SC-10-LoadB-.../.../..."
  TEST_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:12344343:listener/app/SC-10-LoadB-.../.../..."
else
  AWS_ENVIRONMENT="prod"
  AWS_ACCOUNT_ID=""
  FARGATE_STACK_NAME="SC-...."
  LOAD_BALANCER="SC-70-LoadB-..."
  PROD_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:707070707:listener/app/SC-70-LoadB-.../.../..."
  TEST_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:707070707:listener/app/SC-70-LoadB-.../.../..."
fi

PROD_LISTENER_RULE_PRIORITY=$(aws elbv2 describe-rules --listener-arn "${PROD_LISTENER_ARN}" | jq -r '[.Rules[].Priority][0:-1] | map(.|tonumber) | max + 1')
TEST_LISTENER_RULE_PRIORITY=$(aws elbv2 describe-rules --listener-arn "${TEST_LISTENER_ARN}" | jq -r '[.Rules[].Priority][0:-1] | map(.|tonumber) | max + 1')

stackArn=$(aws cloudformation create-stack \
      --stack-name "$APP_NAME-ecs-service" \
      --template-body file://ecs-service.cfn.yml \
      --tags file://../tags-$AWS_ENVIRONMENT.json \
      --parameters \
      ParameterKey=AppName,ParameterValue="$APP_NAME" \
      ParameterKey=FargateStackName,ParameterValue="$FARGATE_STACK_NAME" \
      ParameterKey=LoadBalancerName,ParameterValue="$LOAD_BALANCER" \
      ParameterKey=ProdListenerArn,ParameterValue="$PROD_LISTENER_ARN" \
      ParameterKey=TestListenerArn,ParameterValue="$TEST_LISTENER_ARN" \
      ParameterKey=ProdListenerRulePriority,ParameterValue="$PROD_LISTENER_RULE_PRIORITY" \
      ParameterKey=TestListenerRulePriority,ParameterValue="$TEST_LISTENER_RULE_PRIORITY" \
      --capabilities CAPABILITY_NAMED_IAM | jq -r '.StackId')


echo "Creating stack: $stackArn"
aws cloudformation wait stack-create-complete --stack-name $stackArn

# Using AWS CLI to create Deployment Group as the cloudformation support doesn't exist for Blue/Green deployment type
echo $(aws deploy create-deployment-group \
    --application-name "$APP_NAME" \
    --deployment-group-name "$APP_NAME-ecs-blue-green" \
    --service-role-arn "arn:aws:iam::$AWS_ACCOUNT_ID:role/CodeDeployServiceRole" \
    --load-balancer-info \
      '{
        "targetGroupPairInfoList": [
          {
            "targetGroups": [
              {
                "name": "'$APP_NAME'-1"
              },
              {
                "name": "'$APP_NAME'-2"
              }
            ],
            "prodTrafficRoute": {
              "listenerArns": ["'$PROD_LISTENER_ARN'"]
            },
            "testTrafficRoute": {
              "listenerArns": ["'$TEST_LISTENER_ARN'"]
            }
          }
        ]
      }' \
    --blue-green-deployment-configuration \
      '{
        "terminateBlueInstancesOnDeploymentSuccess": {
          "action": "TERMINATE",
          "terminationWaitTimeInMinutes": 0
        },
        "deploymentReadyOption": {
          "actionOnTimeout": "CONTINUE_DEPLOYMENT",
          "waitTimeInMinutes": 0
        }
      }' \
    --ecs-services serviceName="$APP_NAME",clusterName="kpi-automation" \
    --deployment-style deploymentType="BLUE_GREEN",deploymentOption="WITH_TRAFFIC_CONTROL" \
    --deployment-config-name "CodeDeployDefault.ECSAllAtOnce" \
    --auto-rollback-configuration enabled=true,events="DEPLOYMENT_FAILURE")

echo
echo
echo "|---------------------------------------------------------------------------------------|"
echo "      $APP_NAME ECS Service and CodeDeploy app created successfully"
echo "|---------------------------------------------------------------------------------------|"
echo
echo

