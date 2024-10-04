#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

AWS_CLOUDFRONT_DISTRO_ID_FILE="/tmp/cloudfront-id.txt"
AWS_CLOUDFRONT_POLICY_ID_FILE="/tmp/origin-request-policy-id.txt"
AWS_CLOUDFRONT_CONFIG_UPDATE_JSON="${BASEDIR}/update-config.json"
AWS_CLOUDFRONT_ORIGIN_POLICY_JSON="${BASEDIR}/origin-request-policy.json"
UPDATED_CONFIG_FILE="/tmp/updated-config.json" # Add a file to store the updated config

main() {
#  cloudfront_create_origin_request_policy
  cloudfront_merge_configs
#  cloudfront_update_distribution
}

cloudfront_create_origin_request_policy() {
  log_info "cloudfront" "creating origin request policy"

  out=$(awslocal cloudfront create-origin-request-policy \
    --origin-request-policy-config "file://${AWS_CLOUDFRONT_ORIGIN_POLICY_JSON}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")

  # Capture the Origin Request Policy ID
  ORIGIN_REQUEST_POLICY_ID=$(echo "${out}" | jq -r '.OriginRequestPolicy.Id')
  if [[ -n "$ORIGIN_REQUEST_POLICY_ID" ]]; then
    echo "${ORIGIN_REQUEST_POLICY_ID}" > "${AWS_CLOUDFRONT_POLICY_ID_FILE}"
  else
    log_error "cloudfront" "failed to preserve origin request policy ID"
    exit 1
  fi

  echo "${out}" | while IFS= read -r line
  do
    log_info "cloudfront" "${line}"
  done
}

cloudfront_merge_configs() {
  # Retrieve the CloudFront Distribution ID from file
  if [[ -f "${AWS_CLOUDFRONT_DISTRO_ID_FILE}" ]]; then
    AWS_CLOUDFRONT_DISTRO_ID=$(<"${AWS_CLOUDFRONT_DISTRO_ID_FILE}" tr -d '[:space:]')
  else
    log_error "cloudfront" "CloudFront distribution ID file not found: ${AWS_CLOUDFRONT_DISTRO_ID_FILE}"
    exit 1
  fi

  # Retrieve the Origin Request Policy ID from file
  if [[ -f "${AWS_CLOUDFRONT_POLICY_ID_FILE}" ]]; then
    ORIGIN_REQUEST_POLICY_ID=$(<"${AWS_CLOUDFRONT_POLICY_ID_FILE}" tr -d '[:space:]')
  else
    log_error "cloudfront" "Origin request policy ID file not found: ${AWS_CLOUDFRONT_POLICY_ID_FILE}"
    exit 1
  fi

  response=$(awslocal cloudfront get-distribution-config \
    --id "${AWS_CLOUDFRONT_DISTRO_ID}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")

  # Capture the ETag (required for update)
  ETag=$(echo "${response}" | jq -r '.ETag')
  if [[ -z "$ETag" ]]; then
    log_error "cloudfront" "Failed to capture ETag from current distribution config"
    exit 1
  fi

  # Capture the current distribution configuration
  CURRENT_CONFIG=$(echo "${response}" | jq -r '.DistributionConfig')

  # Read in the updated config chunk
  if [[ -f "${AWS_CLOUDFRONT_CONFIG_UPDATE_JSON}" ]]; then
    NEW_VALUES=$(jq '.' "${AWS_CLOUDFRONT_CONFIG_UPDATE_JSON}")
  else
    log_error "cloudfront" "Config update file not found: ${AWS_CLOUDFRONT_CONFIG_UPDATE_JSON}"
    exit 1
  fi

  # Set the correct origin request policy ID
  NEW_VALUES=$(echo "${NEW_VALUES}" | jq --arg id "${ORIGIN_REQUEST_POLICY_ID}" '.OriginRequestPolicyId = $id')

  # Merge the updated config values into the existing configuration
  UPDATED_CONFIG=$(echo "${CURRENT_CONFIG}" | jq --argjson new "$NEW_VALUES" '.DefaultCacheBehavior.LambdaFunctionAssociations = $new.DefaultCacheBehavior.LambdaFunctionAssociations | .DefaultCacheBehavior.OriginRequestPolicyId = $new.OriginRequestPolicyId')

  # Write the updated config to a temporary file
  log_info "cloudfront" "merged current and updated configs"
  echo "${UPDATED_CONFIG}" > "${UPDATED_CONFIG_FILE}"
  echo "${UPDATED_CONFIG}" | while IFS= read -r line
  do
    log_info "cloudfront" "${line}"
  done
}

cloudfront_update_distribution() {
  log_info "cloudfront" "Updating distribution with new configuration"

  # Update the distribution using the modified configuration
  out=$(awslocal cloudfront update-distribution \
    --id "${AWS_CLOUDFRONT_DISTRO_ID}" \
    --if-match "${ETag}" \
    --distribution-config file://"${UPDATED_CONFIG_FILE}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")

  echo "${out}" | while IFS= read -r line
  do
    log_info "cloudfront" "${line}"
  done
}

main
