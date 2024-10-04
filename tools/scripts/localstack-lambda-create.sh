#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
source "${BASEDIR}/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

AWS_LAMBDA_NAME="lambda"
AWS_LAMBDA_HANDLER="app.handler"
AWS_LAMBDA_IMAGE="000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566/lambda"
AWS_LAMBDA_ROLE="arn:aws:iam::000000000000:role/lambda-role"

main() {
  lambda_create_function
}

lambda_create_function() {
  log_info "lambda" "creating function"
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

main
