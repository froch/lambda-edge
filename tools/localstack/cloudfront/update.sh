#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
source "/tmp/scripts/logs.sh"

main() {
  cloudfront_create_origin_request_policy
#  cloudfront_create_distribution
}

cloudfront_create_origin_request_policy() {
  log_info "cloudfront" "creating origin request policy"
  out=$(awslocal cloudfront create-origin-request-policy \
      --origin-request-policy-config "file://${BASEDIR}/origin-request-policy.json")
  echo "${out}" | while IFS= read -r line
  do
    log_info "cloudfront" "${line}"
  done
}

cloudfront_update_distribution() {
  log_info "cloudfront" "creating distribution"
  out=$(awslocal cloudfront update-distribution \
    --id "E1EXAMPLE" \
    --endpoint-url "http://localhost:4566" \
    --region "us-east-1")
  echo "${out}" | while IFS= read -r line
  do
    log_info "cloudfront" "${line}"
  done
}

main
