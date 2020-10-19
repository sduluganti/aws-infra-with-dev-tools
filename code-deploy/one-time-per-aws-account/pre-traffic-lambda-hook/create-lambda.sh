#!/bin/bash
set -e

functionCode="$(sed "s/'/\"/g"  index.js)"

createStack () {
  echo $(aws cloudformation create-stack \
      --stack-name "code-deploy-pre-traffic-hook-lambda" \
      --template-body file://create-lambda.cfn.yml \
      --tags file://../../../tags-$2.json \
      --parameters \
      ParameterKey=FargateStackName,ParameterValue="$1" \
      ParameterKey=FunctionCode,ParameterValue="'$functionCode'" \
      --capabilities CAPABILITY_AUTO_EXPAND | jq -r '.StackId')
}

# --------------------------------------NONPROD------------------------------------------
export AWS_PROFILE=103299287643/standard-user
fargateStackName="SC-12345-pp-...."
stackArn=$(createStack $fargateStackName "nonprod")
echo "Creating stack in Nonprod: $stackArn"

# ----------------------------------------PROD-------------------------------------------
export AWS_PROFILE=707678851111/standard-user
fargateStackName="SC-707070-pp-..."
stackArn=$(createStack $fargateStackName "prod")
echo "Creating stack in Prod: $stackArn"

aws cloudformation wait stack-create-complete --stack-name $stackArn

echo "Stacks created successfully...!"
