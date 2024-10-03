#!/usr/bin/env bash
set -euxo pipefail

awslocal lambda create-function \
    --function-name lambda-edge \
    --package-type Image \
    --code ImageUri="localhost:4510/lambda-edge" \
    --role arn:aws:iam::000000000000:role/lambda-role \
    --handler app.handler \
    --endpoint-url=http://localhost:4566 \
    --region us-east-1
