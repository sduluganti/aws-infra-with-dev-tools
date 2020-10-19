#!/bin/bash
set -e

projectName=$1
projectRuntime=$2
platform=$3

buildSpec="$(cat buildspec-$projectRuntime-$platform.yml)"

. ../.secrets

function create_stack {
  stackArn=$(aws cloudformation create-stack \
                --stack-name ${projectName}-code-build-project \
                --template-body file://code-build.cfn.yml \
                --tags file://../tags-$AWS_ENVIRONMENT.json \
                --parameters ParameterKey=ProjectName,ParameterValue=$projectName \
                ParameterKey=FargateStackName,ParameterValue="$1" \
                ParameterKey=SecurityGroup,ParameterValue="$2" \
                ParameterKey=AwsEnv,ParameterValue="$AWS_ENVIRONMENT" | jq -r '.StackId')

  echo "Creating $AWS_ENVIRONMENT stack: $stackArn"
  aws cloudformation wait stack-create-complete --stack-name $stackArn

  echo "Adding the buildspec config...!"
  buildSpecUpdate=$(aws codebuild update-project --name $projectName \
      --source type="GITHUB_ENTERPRISE",buildspec="'$buildSpec'",gitCloneDepth=1,location="https://github.platforms.engineering/kpi-automation/$projectName")
}

function create_ghe_webhook {
  echo "Creating Webhook trigger for codebhuild project in GHE"
  payloadUrl=$(echo "$1" | jq -r '.payloadUrl')
  secret=$(echo "$1" | jq -r '.secret')
  curl -X POST -H "Content-Type: application/json" -H "Authorization: token $GHE_ACCESS_TOKEN" \
    -d "{\"name\": \"web\", \"active\": true, \"events\": [\"create\",\"push\",\"pull_request\"], \
    \"config\": { \"url\": \"$payloadUrl\", \"secret\": \"$secret\", \"content_type\": \"json\", \"insecure_ssl\": \"0\" } }" \
    https://github.platforms.engineering/api/v3/repos/kpi-automation/$projectName/hooks
}

# ---------------------Non prod codebuild resource creation---------------------
export AWS_PROFILE=103299287643/standard-user
AWS_ENVIRONMENT="nonprod"

create_stack "..." "sg-..."

webhook=$(aws codebuild create-webhook --project-name $projectName \
              --filter-groups \
                '[
                  [
                    {
                      "type": "EVENT",
                      "pattern": "PULL_REQUEST_CREATED, PULL_REQUEST_UPDATED, PULL_REQUEST_REOPENED, PULL_REQUEST_MERGED, PUSH",
                      "excludeMatchedPattern": false
                    },
                    {
                      "type": "HEAD_REF",
                      "pattern": "^refs/tags/",
                      "excludeMatchedPattern": true
                    }
                  ]
                ]'\
              | jq '.webhook')

create_ghe_webhook "$webhook"

echo
echo
echo "|-------------------------------------------------------------------------|"
echo "|------------  NonProd codebuild resource creation completed  ------------|"
echo "|-------------------------------------------------------------------------|"
echo
echo


# ---------------------Prod codebuild resource creation---------------------
export AWS_PROFILE=707678851111/standard-user
AWS_ENVIRONMENT="prod"

create_stack "..." "sg-..."

webhook=$(aws codebuild create-webhook --project-name $projectName \
              --filter-groups \
                '[
                  [
                    {
                      "type": "EVENT",
                      "pattern": "PULL_REQUEST_CREATED, PULL_REQUEST_UPDATED, PULL_REQUEST_REOPENED, PULL_REQUEST_MERGED, PUSH",
                      "excludeMatchedPattern": false
                    },
                    {
                      "type": "HEAD_REF",
                      "pattern": "^refs/heads/",
                      "excludeMatchedPattern": true
                    }
                  ],
                  [
                    {
                      "type": "EVENT",
                      "pattern": "PUSH",
                      "excludeMatchedPattern": false
                    },
                    {
                      "type": "HEAD_REF",
                      "pattern": "^refs/tags/",
                      "excludeMatchedPattern": false
                    }
                  ]
                ]'\
              | jq '.webhook')

create_ghe_webhook "$webhook"

echo
echo
echo "|-------------------------------------------------------------------------|"
echo "|-------------  Prod codebuild resource creation completed  --------------|"
echo "|-------------------------------------------------------------------------|"
echo

