#!/usr/bin/env bash
set -euxo pipefail

# :-( only in PRO image now
# awslocal ecr create-repository \
#   --repository-name lambda-edge \
#   --endpoint-url=http://localhost:4566 \
#   --region us-east-1
