#!/usr/bin/env bash
set -euo pipefail

source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

AWS_LAMBDA_NAME="lambda"

main() {
  lambda_get_function_config
}

lambda_get_function_config() {
  log_info "lambda" "fetch function config"
  out=$(awslocal lambda get-function-configuration \
    --function-name ${AWS_LAMBDA_NAME} \
      --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
      --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "lambda" "${line}"
  done
}

main
