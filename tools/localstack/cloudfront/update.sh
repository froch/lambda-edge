#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
source "/tmp/scripts/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

AWS_CLOUDFRONT_DISTRO_ID_FILE="/tmp/cloudfront-id.txt"
AWS_CLOUDFRONT_POLICY_ID_FILE="/tmp/origin-request-policy-id.txt"
AWS_CLOUDFRONT_CONFIG_UPDATE_JSON="${BASEDIR}/update-config.json"
AWS_CLOUDFRONT_ORIGIN_POLICY_JSON="${BASEDIR}/update-origin-request-policy.json"
UPDATED_CONFIG_FILE="/tmp/updated-config.json" # Add a file to store the updated config

main() {
  cloudfront_create_origin_request_policy
  cloudfront_merge_configs
  cloudfront_update_distribution
}

cloudfront_create_origin_request_policy() {
  log_info "cloudfront" "create origin request policy"

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
  if [[ -f "${AWS_CLOUDFRONT_DISTRO_ID_FILE}" ]]; then
    AWS_CLOUDFRONT_DISTRO_ID=$(<"${AWS_CLOUDFRONT_DISTRO_ID_FILE}" tr -d '[:space:]')
  else
    log_error "cloudfront" "distribution ID file not found: ${AWS_CLOUDFRONT_DISTRO_ID_FILE}"
    exit 1
  fi

  if [[ -f "${AWS_CLOUDFRONT_POLICY_ID_FILE}" ]]; then
    ORIGIN_REQUEST_POLICY_ID=$(<"${AWS_CLOUDFRONT_POLICY_ID_FILE}" tr -d '[:space:]')
  else
    log_error "cloudfront" "origin request policy ID file not found: ${AWS_CLOUDFRONT_POLICY_ID_FILE}"
    exit 1
  fi

  log_info "cloudfront" "fetch current distribution configuration"
  response=$(awslocal cloudfront get-distribution-config \
    --id "${AWS_CLOUDFRONT_DISTRO_ID}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  CURRENT_CONFIG=$(echo "${response}" | jq -r '.DistributionConfig')

  log_info "cloudfront" "capture ETag from current distribution config"
  ETag=$(echo "${response}" | jq -r '.ETag')
  if [[ -z "$ETag" ]]; then
    log_error "cloudfront" "failed to capture ETag"
    exit 1
  fi

  log_info "cloudfront" "load updated config values"
  if [[ -f "${AWS_CLOUDFRONT_CONFIG_UPDATE_JSON}" ]]; then
    NEW_VALUES=$(jq '.' "${AWS_CLOUDFRONT_CONFIG_UPDATE_JSON}")
  else
    log_error "cloudfront" "config update file not found: ${AWS_CLOUDFRONT_CONFIG_UPDATE_JSON}"
    exit 1
  fi

  log_info "cloudfront" "set origin request policy ID to default cache behavior"
  NEW_VALUES=$(echo "${NEW_VALUES}" | jq --arg id "${ORIGIN_REQUEST_POLICY_ID}" '.DefaultCacheBehavior.OriginRequestPolicyId = $id')

  log_info "cloudfront" "extract TargetOriginId from DefaultCacheBehavior"
  TARGET_ORIGIN_ID=$(echo "${CURRENT_CONFIG}" | jq -r '.DefaultCacheBehavior.TargetOriginId')
  if [[ -z "$TARGET_ORIGIN_ID" ]]; then
    log_error "cloudfront" "Failed to extract TargetOriginId from DefaultCacheBehavior"
    exit 1
  fi

  log_info "cloudfront" "set TargetOriginId for all CacheBehaviors"
  NEW_VALUES=$(echo "${NEW_VALUES}" | jq --arg targetOriginId "${TARGET_ORIGIN_ID}" '
    .CacheBehaviors.Items |= map(.TargetOriginId = $targetOriginId)
  ')

  log_info "cloudfront" "merge current and updated configs"
  UPDATED_CONFIG=$(echo "${CURRENT_CONFIG}" | jq --argjson new "$NEW_VALUES" '
    .DefaultCacheBehavior.LambdaFunctionAssociations = $new.DefaultCacheBehavior.LambdaFunctionAssociations |
    .DefaultCacheBehavior.OriginRequestPolicyId = $new.DefaultCacheBehavior.OriginRequestPolicyId |
    .CacheBehaviors = $new.CacheBehaviors
  ')

  log_info "cloudfront" "write updated config to file"
  echo "${UPDATED_CONFIG}" > "${UPDATED_CONFIG_FILE}"
#  echo "${UPDATED_CONFIG}" | while IFS= read -r line
#  do
#    log_info "cloudfront" "${line}"
#  done
}

cloudfront_update_distribution() {
  log_info "cloudfront" "update distribution with new config"

  out=$(awslocal cloudfront update-distribution \
    --id "${AWS_CLOUDFRONT_DISTRO_ID}" \
    --if-match "${ETag}" \
    --distribution-config "file://${UPDATED_CONFIG_FILE}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")

  echo "${out}" | while IFS= read -r line
  do
    log_info "cloudfront" "${line}"
  done
}

main
