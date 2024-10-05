#!/usr/bin/env bash
set -euo pipefail

source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

AWS_LAMBDA_NAME="lambda"

main() {
  lambda_get_iam_role
  lambda_get_iam_policy_attachments
}

lambda_get_iam_role() {
  log_info "lambda" "fetch IAM role"
  out=$(awslocal iam get-role \
    --role-name "${AWS_LAMBDA_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "lambda" "${line}"
  done
}

lambda_get_iam_policy_attachments() {
  log_info "lambda" "fetch IAM policy attachments"
  out=$(awslocal iam list-attached-role-policies \
    --role-name "${AWS_LAMBDA_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "lambda" "${line}"
  done
}

main
