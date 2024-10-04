#!/usr/bin/env bash
set -euo pipefail

source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

AWS_LAMBDA_NAME="lambda"
AWS_LAMBDA_HANDLER="app.handler"
AWS_LAMBDA_IMAGE="000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566/lambda"
AWS_LAMBDA_ROLE="arn:aws:iam::000000000000:role/lambda"
AWS_CLOUDFRONT_ID_FILE="/tmp/cloudfront-id.txt"

main() {
  lambda_create_function
  lambda_allow_cloudfront_invoke
}

lambda_create_function() {
  log_info "lambda" "creating Lambda function"
  out=$(awslocal lambda create-function \
    --function-name "${AWS_LAMBDA_NAME}" \
    --package-type Image \
    --code ImageUri="${AWS_LAMBDA_IMAGE}" \
    --role "${AWS_LAMBDA_ROLE}" \
    --handler "${AWS_LAMBDA_HANDLER}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "lambda" "${line}"
  done
}

lambda_allow_cloudfront_invoke() {
  log_info "lambda" "allow CloudFront to invoke Lambda"

  # get the cloudfront distro id saved on init
  if [[ -f "${AWS_CLOUDFRONT_ID_FILE}" ]]; then
    AWS_CLOUDFRONT_DISTRIBUTION_ID=$(<"${AWS_CLOUDFRONT_ID_FILE}" tr -d '[:space:]')
  else
    log_error "lambda" "CloudFront distribution ID file not found: ${AWS_CLOUDFRONT_ID_FILE}"
    exit 1
  fi

  # add permission for cloudfront to invoke lambda
  out=$(awslocal lambda add-permission \
    --function-name "${AWS_LAMBDA_NAME}" \
    --statement-id "AllowCloudFrontInvoke" \
    --action "lambda:InvokeFunction" \
    --principal "cloudfront.amazonaws.com" \
    --source-arn "arn:aws:cloudfront:${AWS_LOCAL_REGION}:000000000000:distribution/${AWS_CLOUDFRONT_DISTRIBUTION_ID}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  parsed=$(echo "${out}" | jq '.Statement | fromjson')
  echo "${parsed}" | jq | while IFS= read -r line
  do
    log_info "lambda" "${line}"
  done
}

main
