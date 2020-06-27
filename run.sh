#!/bin/bash
set -e
declare -A all && eval all=($ALL)

stack_name=$SHORT_ENV-$SHORT_SETUP

stack_name=$(echo $stack_name | sed s/_/-/g )
echo stack_name $stack_name

bucket_name=${stack_name}-bucket-deploy
echo bucket_name $bucket_name

if [ "$1" = "delete" ]; then

  aws cloudformation delete-stack --region $STACK_REGION \
    --stack-name $stack_name
  aws cloudformation wait stack-delete-complete --region $STACK_REGION \
    --stack-name $stack_name

  aws s3 rb s3://$bucket_name --force

else

  if ! aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
    aws s3 mb s3://$bucket_name --region $SAM_S3_BUCKET_DEPLOY_REGION
  fi

  sam deploy --stack-name $stack_name \
             --s3-bucket $bucket_name \
             --region $STACK_REGION \
             --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM

fi