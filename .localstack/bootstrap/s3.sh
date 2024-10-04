#!/usr/bin/env bash
set -euxo pipefail

BASEDIR=$(dirname "$0")

awslocal s3 mb \
  "s3://nimble-bucket" \
  --endpoint-url "http://localhost:4566" \
  --region "us-east-1"

awslocal s3 cp \
  "${BASEDIR}/this-is-fine.gif" \
  "s3://nimble-bucket/this-is-fine.gif" \
  --endpoint-url "http://localhost:4566" \
  --region "us-east-1"

# http://localhost:4566/nimble-bucket/this-is-fine.gif
# http://nimble-bucket.s3.us-east-1.localhost.localstack.cloud:4566/this-is-fine.gif
# http://nimble-bucket.s3.localhost.localstack.cloud:4566/this-is-fine.gif
# http://s3.us-east-1.localhost.localstack.cloud:4566/nimble-bucket/this-is-fine.gif
