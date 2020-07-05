#!/bin/sh
set -e
stack_name=$SHORT_SETUP-$SHORT_ENV

stack_name=$(echo "$stack_name" | sed s/_/-/g )
echo stack_name "$stack_name"

bucket_name=${stack_name}-bucket-deploy
echo bucket_name "$bucket_name"
echo ""

if [ "$1" = "delete" ]; then

  echo "delete $stack_name $STACK_REGION"

  aws cloudformation delete-stack --region "$STACK_REGION" \
    --stack-name "$stack_name"
  aws cloudformation wait stack-delete-complete --region "$STACK_REGION" \
    --stack-name "$stack_name"

  aws s3 rb "s3://$bucket_name" --force

elif [ "$1" = "status" ]; then

  query=$(printf 'StackSummaries[?StackStatus!=`DELETE_COMPLETE`]|[?starts_with(StackName,`%s`)==`true`]|[].[StackName,StackStatus,LastUpdateTime]' $stack_name)
  aws cloudformation list-stacks \
    --region "$STACK_REGION" \
    --query "$query" \
    --output text

  aws cloudformation --region "$STACK_REGION" \
      list-stack-resources \
      --stack-name "$stack_name" \
      --query 'StackResourceSummaries[?ResourceStatus!=`CREATE_COMPLETE`]|[?ResourceStatus!=`UPDATE_COMPLETE`].[LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
      --output text | \
  awk '{printf("  %s\n",$0)}'

else

  if ! aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
    aws s3 mb "s3://$bucket_name" --region "$SAM_S3_BUCKET_DEPLOY_REGION"
  fi

  sam deploy --stack-name "$stack_name" \
             --s3-bucket "$bucket_name" \
             --region "$STACK_REGION" \
             --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
             --parameter-overrides "$PARAMS"
fi