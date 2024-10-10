# Edge Lambda

- We need to build a Lambda@Edge function that forwards requests to an external server for authorization.
- We'll use the AWS SDK for Node.js to build the Lambda function.
- However, since we're targeting the Edge, we need to keep things ultra lightweight.
- Our goal is to trigger the Lambda function on CloudFront `viewer-request` events, which impose a 1MB size limit of the function code size.
- We'll be using `typescript` and `pnpm` for this project.

## Before you begin

- Check the `.envrc` at the root of this repository.
- The Edge Lambda needs the `AUTHZ_HOST`, `AUTHZ_PORT`, and `AUTHZ_PATH` environment variables.
- We fall back to sane localhost defaults if these are not set.
- For Docker, setting the `AWS_ECR_REPOSITORY` is also a good idea; set it to either localstack, or a remote.
- For deployment, we must resort a `config.json` sister file to the `app.js` artifact.
- This is another limitation of Edge Lambda; it does not support custom environment variables.
- When building the lambda Zipfile, we'll also need `AWS_S3_BUCKET_NAME` and `AWS_S3_BUCKET_PATH` set.

## HOWTO

- From the root of this repository, these Makefile targets are available:

```bash
# resetting the packages
$ make nuke-lambda-dev
$ make nuke-lambda-prod

# linting and formatting
$ make lint-lambda
$ make fmt-lambda

# tests
$ make test-lambda

# build
$ make build-lambda

# docker
$ make docker-build-authz
$ make docker-run-authz
$ make docker-push-authz

# building a zipfile for AWS
$ make zip-lambda
```
