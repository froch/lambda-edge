#!/usr/bin/env bash
set -euxo pipefail

awslocal s3 mb \
  s3://nimble-bucket \
  --endpoint-url=http://localhost:4566 \
  --region us-east-1

awslocal s3 cp \
  ./this-is-fine.gif \
  s3://nimble-bucket/this-is-fine.gif \
  --endpoint-url=http://localhost:4566 \
  --region us-east-1
