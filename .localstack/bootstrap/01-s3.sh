#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
source "${BASEDIR}/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

FILE_NAME="s3-this-is-fine.gif"
S3_BUCKET_NAME="froch-bucket"
S3_KEY_NAME="this-is-fine.gif"

main() {
  s3_create_bucket
  s3_upload_file
  s3_list_bucket
}

s3_create_bucket() {
  log_info "s3" "creating bucket: s3://${S3_BUCKET_NAME}"
  awslocal s3 mb \
    "s3://${S3_BUCKET_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}"
}

s3_upload_file() {
  for FILE in "${BASEDIR}"/*.gif; do
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

s3_list_bucket() {
  log_info "s3" "listing bucket: s3://${S3_BUCKET_NAME}"
  contents=$(awslocal s3 ls \
    "s3://${S3_BUCKET_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${contents}" | while IFS= read -r line
  do
    log_info "s3" "bucket contents: ${line}"
  done
}

main

# example S3 URLs
# http://localhost:4566/froch-bucket/this-is-fine.gif
# http://froch-bucket.s3.us-east-1.localhost.localstack.cloud:4566/this-is-fine.gif
# http://froch-bucket.s3.localhost.localstack.cloud:4566/this-is-fine.gif
# http://s3.us-east-1.localhost.localstack.cloud:4566/froch-bucket/this-is-fine.gif
