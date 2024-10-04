#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
source "${BASEDIR}/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

CLOUDFRONT_S3_ORIGIN="froch-bucket.s3.localhost.localstack.cloud:4566"

main() {
  cloudfront_create_distribution
}

cloudfront_create_origin_request_policy() {
  awslocal cloudfront create-origin-request-policy \
      --origin-request-policy-config '{
          "Name": "ForwardAuthHeaderPolicy",
          "Comment": "Forward authentication header to Lambda@Edge",
          "HeadersConfig": {
              "HeaderBehavior": "whitelist",
              "Headers": {
                  "Quantity": 1,
                  "Items": ["authentication"]
              }
          },
          "CookiesConfig": {
              "CookieBehavior": "none"
          },
          "QueryStringsConfig": {
              "QueryStringBehavior": "none"
          }
      }'
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
