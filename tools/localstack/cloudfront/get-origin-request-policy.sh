#!/usr/bin/env bash
set -euo pipefail

source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

AWS_CLOUDFRONT_ORIGIN_POLICY_ID="76be8940-f4f9-4084-afac-608a5e67fffa"

main() {
  cloudfront_get_origin_request_policy
}

cloudfront_get_origin_request_policy() {
  log_info "cloudfront" "getting origin request policy"
  out=$(awslocal cloudfront get-origin-request-policy \
    --id "${AWS_CLOUDFRONT_ORIGIN_POLICY_ID}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "cloudfront" "${line}"
  done
}

main
