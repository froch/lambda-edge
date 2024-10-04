#!/usr/bin/env bash
set -euxo pipefail

BASEDIR=$(dirname "$0")
source "${BASEDIR}/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

CLOUDFRONT_S3_ORIGIN="froch-bucket.s3.localhost.localstack.cloud:4566"

main() {
  cloudfront_create_distribution
}

cloudfront_create_distribution() {
  log_info "cloudfront" "creating distribution"
  out=$(awslocal cloudfront create-distribution \
    --origin-domain-name "${CLOUDFRONT_S3_ORIGIN}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "cloudfront" "${line}"
  done
}

main
