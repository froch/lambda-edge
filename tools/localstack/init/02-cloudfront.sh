#!/usr/bin/env bash
set -euo pipefail

source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

AWS_CLOUDFRONT_S3_ORIGIN="froch.s3.localhost.localstack.cloud:4566"
AWS_CLOUDFRONT_ID_FILE="/tmp/cloudfront-id.txt"

main() {
  cloudfront_create_distribution
}

cloudfront_create_distribution() {
  log_info "cloudfront" "creating distribution"
  out=$(awslocal cloudfront create-distribution \
    --origin-domain-name "${AWS_CLOUDFRONT_S3_ORIGIN}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")

  echo "${out}" | while IFS= read -r line
  do
    log_info "cloudfront" "${line}"
  done

  AWS_CLOUDFRONT_ID=$(echo "${out}" | jq -r '.Distribution.Id')
  if [[ -n "${AWS_CLOUDFRONT_ID}" ]]; then
    echo "${AWS_CLOUDFRONT_ID}" > "${AWS_CLOUDFRONT_ID_FILE}"
    log_info "cloudfront" "CloudFront distribution ID: ${AWS_CLOUDFRONT_ID}"
  else
    log_error "cloudfront" "Failed to extract CloudFront distribution ID"
    exit 1
  fi
}

main
