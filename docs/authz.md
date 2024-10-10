# authz

- We need to build a simple webserver that can handle requests from the Edge Lambda function.
- We just need a handful of endpoints.
- We'll implement tests for the server as well.
- We'll dockerize the server and run it in the same network as the Lambda function.

## Before you begin

- Check the `.envrc` at the root of this repository.
- The `authz` server needs the `AUTHZ_HEADER` environment variable set.
- This represents the expected header value on which to return `HTTP200`.
- For Docker, setting the `AWS_ECR_REPOSITORY` is also a good idea; set it to either localstack, or a remote.
- If you want to deploy to EKS, you'll also need to set `AWS_EKS_KUBECONTEXT`.

## HOWTO

- From the root of this repository;

```bash
# linting and formatting
$ make lint-authz
$ make fmt-authz

# tests
$ make test-authz

# build
$ make build-authz
$ make install-authz

# docker
$ make docker-build-authz
$ make docker-run-authz
$ make docker-push-authz

# kubernetes
$ make k8s-deploy-authz
```
