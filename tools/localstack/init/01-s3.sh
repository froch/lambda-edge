#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

ASSETS_DIR="/tmp/assets"
AWS_S3_ASSETS_BUCKET_NAME="froch"
AWS_S3_LOGS_BUCKET_NAME="logs"
AWS_S3_LOGS_POLICY_JSON="file://${BASEDIR}/01-s3-logs-policy.json"

main() {
  s3_create_assets_bucket
  s3_upload_assets

  s3_create_cloudfront_logs_bucket
  s3_add_cloudfront_logs_policy
}

# -------- assets -------- #

s3_create_assets_bucket() {
  log_info "s3" "creating bucket: s3://${AWS_S3_ASSETS_BUCKET_NAME}"
  out=$(awslocal s3 mb \
    "s3://${AWS_S3_ASSETS_BUCKET_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "s3" "${line}"
  done
}

s3_upload_assets() {
  for FILE in "${ASSETS_DIR}"/*.gif; do
    filename=$(basename "${FILE}")
    keyname="${filename}"
    log_info "s3" "uploading file: ${FILE} --> s3://${AWS_S3_ASSETS_BUCKET_NAME}/${keyname}"
    out=$(awslocal s3 cp \
      "${FILE}" \
      "s3://${AWS_S3_ASSETS_BUCKET_NAME}/${keyname}" \
      --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
      --region "${AWS_LOCAL_REGION}")
    echo "${out}" | while IFS= read -r line
    do
      log_info "s3" "${line}"
    done
  done
}

# -------- CloudFront logs -------- #

s3_create_logs_bucket() {
  log_info "s3" "creating CloudFront logs bucket: s3://${AWS_S3_LOGS_BUCKET_NAME}"
  out=$(awslocal s3 mb \
    "s3://${AWS_S3_LOGS_BUCKET_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "s3" "${line}"
  done
}

s3_add_logs_policy() {
  log_info "s3" "adding CloudFront log writing policy to bucket: s3://${AWS_S3_LOGS_BUCKET_NAME}"
  out=$(awslocal s3api put-bucket-policy \
    --bucket "${AWS_S3_LOGS_BUCKET_NAME}" \
    --policy "${AWS_S3_LOGS_POLICY_JSON}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "s3" "${line}"
  done
}

main

# example S3 URLs for assets
# http://localhost:4566/froch/this-is-fine.gif
# http://froch.s3.us-east-1.localhost.localstack.cloud:4566/this-is-fine.gif
# http://froch.s3.localhost.localstack.cloud:4566/this-is-fine.gif
# http://s3.us-east-1.localhost.localstack.cloud:4566/froch/this-is-fine.gif

# example S3 URL for logs bucket
# http://logs.s3.localhost.localstack.cloud:4566
