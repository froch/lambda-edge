#!/usr/bin/env bash
set -euxo pipefail

BASEDIR=$(dirname "$0")

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"
FILE_NAME="this-is-fine.gif"
S3_BUCKET_NAME="froch-bucket"
S3_KEY_NAME="this-is-fine.gif"

main() {
  s3_create_bucket
  s3_upload_file
}

s3_create_bucket() {
  log_info "s3" "creating bucket: ${S3_BUCKET_NAME}"
  awslocal s3 mb \
    "s3://${S3_BUCKET_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}"
}

s3_upload_file() {
  log_info "s3" "uploading file: ${BASEDIR}/${FILE_NAME} --> s3://${S3_BUCKET_NAME}/${S3_KEY_NAME}"
  awslocal s3 cp \
    "${BASEDIR}/${FILE_NAME}" \
    "s3://${S3_BUCKET_NAME}/${S3_KEY_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}"
}

log_info(){
  # $1 is the module name
  # $2 is the message
  BL_GREEN='\033[0;92m'
  BL_GRAY='\033[0;90m'
  B_GRAY='\033[1;37m'
  NC='\033[0m'
  set +u
  echo -e "${BL_GRAY}[$(date "+%Y-%m-%dT%T%z")]${NC} ${BL_GREEN}INFO${NC} ${BL_GRAY}$1${NC} // ${B_GRAY}$2${NC}"
  set -u
}

main

# http://localhost:4566/froch-bucket/this-is-fine.gif
# http://froch-bucket.s3.us-east-1.localhost.localstack.cloud:4566/this-is-fine.gif
# http://froch-bucket.s3.localhost.localstack.cloud:4566/this-is-fine.gif
# http://s3.us-east-1.localhost.localstack.cloud:4566/froch-bucket/this-is-fine.gif
