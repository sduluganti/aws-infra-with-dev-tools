#!/bin/bash
set -e

createStack () {
  echo $(aws cloudformation create-stack \
      --stack-name "placeholder-ecr-repo" \
      --template-body file://placeholder-ecr-repo.cfn.yml \
      --tags file://../../../tags-$1.json | jq -r '.StackId')
}

# --------------------------------------NONPROD------------------------------------------
export AWS_PROFILE=103299287643/standard-user
stackArn=$(createStack "nonprod")
echo "Creating stack in Nonprod: $stackArn"

# ----------------------------------------PROD-------------------------------------------
export AWS_PROFILE=707678851111/standard-user
stackArn=$(createStack "prod")
echo "Creating stack in Prod: $stackArn"

aws cloudformation wait stack-create-complete --stack-name $stackArn

echo "Stacks created successfully...!"
