#!/usr/bin/env bash
set -euo pipefail

source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

AWS_CLOUDFRONT_DISTRO_ID_FILE="/tmp/cloudfront-id.txt"

main() {
  cloudfront_get_distribution_config
}

cloudfront_get_distribution_config() {
    if [[ -f "${AWS_CLOUDFRONT_DISTRO_ID_FILE}" ]]; then
      AWS_CLOUDFRONT_DISTRO_ID=$(<"${AWS_CLOUDFRONT_DISTRO_ID_FILE}" tr -d '[:space:]')
    else
      log_error "cloudfront" "CloudFront distribution ID file not found: ${AWS_CLOUDFRONT_DISTRO_ID_FILE}"
      exit 1
    fi

    out=$(awslocal cloudfront get-distribution-config \
        --id "${AWS_CLOUDFRONT_DISTRO_ID}" \
        --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
        --region "${AWS_LOCAL_REGION}")
    echo "${out}" | while IFS= read -r line
    do
      log_info "cloudfront" "${line}"
    done
}

main
