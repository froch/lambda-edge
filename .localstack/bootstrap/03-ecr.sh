#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
source "${BASEDIR}/logs.sh"

AWS_LOCAL_ENDPOINT_URL="http://localhost:4566"
AWS_LOCAL_REGION="us-east-1"

main() {
    local repositories=(
      "authz"
      "lambda"
    )
    log_info "ecr" "creating ECR repositories"
    for repo in "${repositories[@]}"; do
      ecr_create_repo "$repo"
    done
}

ecr_create_repo() {
  local repo="${1}"
  out=$(awslocal ecr create-repository \
    --repository-name "${repo}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
  echo "${out}" | while IFS= read -r line
  do
    log_info "ecr" "${line}"
  done
}

main
