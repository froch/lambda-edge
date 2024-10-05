#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

AWS_IAM_LAMBDA_ROLE_NAME="lambda"
AWS_IAM_LAMBDA_TRUST_POLICY_JSON="file://${BASEDIR}/04-iam-lambda-policy-trust.json"

AWS_IAM_LAMBDA_CLOUDFRONT_POLICY_NAME="AllowCloudFrontAccess"
AWS_IAM_LAMBDA_ECR_POLICY_NAME="AllowECRAccess"
AWS_IAM_LAMBDA_LOGS_POLICY_NAME="AllowCloudWatchLogsAccess"
AWS_IAM_LAMBDA_S3_POLICY_NAME="AllowS3Access"

AWS_IAM_LAMBDA_CLOUDFRONT_POLICY_JSON="file://${BASEDIR}/04-iam-lambda-policy-cloudfront.json"
AWS_IAM_LAMBDA_ECR_POLICY_JSON="file://${BASEDIR}/04-iam-lambda-policy-ecr.json"
AWS_IAM_LAMBDA_LOGS_POLICY_JSON="file://${BASEDIR}/04-iam-lambda-policy-logs.json"
AWS_IAM_LAMBDA_S3_POLICY_JSON="file://${BASEDIR}/04-iam-lambda-policy-s3.json"

main() {
  iam_lambda_create_role

  iam_lambda_policy_cloudfront
  iam_lambda_policy_ecr
  iam_lambda_policy_logs
  iam_lambda_policy_s3
}

iam_lambda_create_role() {
  log_info "iam" "create lambda role"
  out=$(awslocal iam create-role \
    --role-name "${AWS_IAM_LAMBDA_ROLE_NAME}" \
    --assume-role-policy-document "${AWS_IAM_LAMBDA_TRUST_POLICY_JSON}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "iam" "${line}"
  done
}

iam_lambda_policy_cloudfront() {
  log_info "iam" "create lambda cloudfront policy"
  out=$(awslocal iam create-policy \
      --policy-name "${AWS_IAM_LAMBDA_CLOUDFRONT_POLICY_NAME}" \
      --policy-document "${AWS_IAM_LAMBDA_CLOUDFRONT_POLICY_JSON}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "iam" "${line}"
  done

  log_info "iam" "attach lambda cloudfront policy"
  out=$(awslocal iam attach-role-policy \
      --role-name "${AWS_IAM_LAMBDA_ROLE_NAME}" \
      --policy-arn "arn:aws:iam::000000000000:policy/${AWS_IAM_LAMBDA_CLOUDFRONT_POLICY_NAME}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "iam" "${line}"
  done
}

iam_lambda_policy_ecr() {
  log_info "iam" "create lambda ECR policy"
  out=$(awslocal iam create-policy \
      --policy-name "${AWS_IAM_LAMBDA_ECR_POLICY_NAME}" \
      --policy-document "${AWS_IAM_LAMBDA_ECR_POLICY_JSON}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "iam" "${line}"
  done

  log_info "iam" "attach lambda ECR policy"
  out=$(awslocal iam attach-role-policy \
      --role-name "${AWS_IAM_LAMBDA_ROLE_NAME}" \
      --policy-arn "arn:aws:iam::000000000000:policy/${AWS_IAM_LAMBDA_ECR_POLICY_NAME}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "iam" "${line}"
  done
}

iam_lambda_policy_logs() {
  log_info "logs" "creating log group"
  out=$(awslocal logs create-log-group \
    --log-group-name "/aws/lambda/${AWS_IAM_LAMBDA_ROLE_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "lambda" "${line}"
  done

  log_info "iam" "create lambda logs policy"
  out=$(awslocal iam create-policy \
      --policy-name "${AWS_IAM_LAMBDA_LOGS_POLICY_NAME}" \
      --policy-document "${AWS_IAM_LAMBDA_LOGS_POLICY_JSON}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "iam" "${line}"
  done

  log_info "iam" "attach lambda logs policy"
  out=$(awslocal iam attach-role-policy \
      --role-name "${AWS_IAM_LAMBDA_ROLE_NAME}" \
      --policy-arn "arn:aws:iam::000000000000:policy/${AWS_IAM_LAMBDA_LOGS_POLICY_NAME}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "iam" "${line}"
  done
}

iam_lambda_policy_s3() {
  log_info "iam" "create lambda S3 policy"
  out=$(awslocal iam create-policy \
      --policy-name "${AWS_IAM_LAMBDA_S3_POLICY_NAME}" \
      --policy-document "${AWS_IAM_LAMBDA_S3_POLICY_JSON}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "iam" "${line}"
  done

  log_info "iam" "attach lambda S3 policy"
  out=$(awslocal iam attach-role-policy \
      --role-name "${AWS_IAM_LAMBDA_ROLE_NAME}" \
      --policy-arn "arn:aws:iam::000000000000:policy/${AWS_IAM_LAMBDA_S3_POLICY_NAME}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "iam" "${line}"
  done
}

main
