#!/bin/bash
set -e


helpFunction()
{
  echo ""
  echo "Usage: $0 AppName=<app-name> IsDevEnvNeeded=<yes|no> RunTime=<run-time> Platform=<platform>"
  echo -e "\t-AppName: The application/repo name"
  echo -e "\t-IsDevEnvNeeded: 'yes', if you need dev env in nonprod OR 'no'"
  echo -e "\t-RunTime: The runtime of the app 'nodejs' OR 'scala'"
  echo -e "\t-Platform: ecs OR lambda"
  exit 1
}

for ARGUMENT in "$@"
do
  KEY=$(echo $ARGUMENT | cut -f1 -d=)
  VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

  case "$KEY" in
        AppName)            AppName=${VALUE} ;;
        IsDevEnvNeeded)     IsDevEnvNeeded=${VALUE} ;;     
        RunTime)            RunTime=${VALUE} ;;     
        Platform)           Platform=${VALUE} ;;     
        *) helpFunction ;;
  esac    
done

if [ -z "$AppName" ] || [ -z "$IsDevEnvNeeded" ] || [ -z "$RunTime" ] || [ -z "$Platform" ]; then
  echo ""
  echo "Some or all of the parameters are empty";
  helpFunction
elif  [ "$IsDevEnvNeeded" != "yes" ] && [ "$IsDevEnvNeeded" != "no" ]; then
  echo ""
  echo "IsDevEnvNeeded param value invalid";
  helpFunction
elif  [ "$RunTime" != "nodejs" ] && [ "$RunTime" != "scala" ]; then
  echo ""
  echo "RunTime param value invalid";
  helpFunction
elif  [ "$Platform" != "ecs" ] && [ "$Platform" != "lambda" ]; then
  echo ""
  echo "Platform param value invalid";
  helpFunction
fi


echo "Creating codebuild project for nonprod and prod AWS"
cd code-build
./create-project.sh $AppName $RunTime $Platform
cd ..

if [ "$Platform" == "ecs" ]; then
  
  cd code-deploy
  
  export AWS_PROFILE=103299287643/standard-user
  if  [ "$IsDevEnvNeeded" = "yes" ]; then
    echo  "Creating ECS service and CodeDeploy resources for $AppName-dev in nonprod"
    ./create-service.sh "$AppName-dev"
  fi

  echo  "Creating ECS service and CodeDeploy resources for $AppName in nonprod"
  ./create-service.sh $AppName

  export AWS_PROFILE=707678851111/standard-user
  echo  "Creating ECS service and CodeDeploy resources for $AppName in prod"
  ./create-service.sh $AppName

  cd ..

fi