#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

ASSETS_DIR="/tmp/assets"
S3_BUCKET_NAME="froch-bucket"
S3_KEY_NAME="this-is-fine.gif"

main() {
  s3_create_bucket
  s3_upload_file
}

s3_create_bucket() {
  log_info "s3" "creating bucket: s3://${S3_BUCKET_NAME}"
  awslocal s3 mb \
    "s3://${S3_BUCKET_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}"
}

s3_upload_file() {
  for FILE in "${ASSETS_DIR}"/*.gif; do
    FILE_NAME=$(basename "${FILE}")
    S3_KEY_NAME="${FILE_NAME}"
    log_info "s3" "uploading file: ${FILE} --> s3://${S3_BUCKET_NAME}/${S3_KEY_NAME}"
    awslocal s3 cp \
      "${FILE}" \
      "s3://${S3_BUCKET_NAME}/${S3_KEY_NAME}" \
      --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
      --region "${AWS_LOCAL_REGION}"
  done
}

main

# example S3 URLs
# http://localhost:4566/froch-bucket/this-is-fine.gif
# http://froch-bucket.s3.us-east-1.localhost.localstack.cloud:4566/this-is-fine.gif
# http://froch-bucket.s3.localhost.localstack.cloud:4566/this-is-fine.gif
# http://s3.us-east-1.localhost.localstack.cloud:4566/froch-bucket/this-is-fine.gif
