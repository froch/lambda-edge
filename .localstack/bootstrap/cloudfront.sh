#!/usr/bin/env bash
set -euxo pipefail

BASEDIR=$(dirname "$0")

awslocal cloudfront create-distribution \
  --distribution-config "file://${BASEDIR}/cloudfront-config.json"
