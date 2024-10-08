# localstack

- [localstack](https://docs.localstack.cloud/user-guide/aws/lambda/) is a stellar tool for local development.
- However at time of writing, our initial premise is incorrect.
- We cannot use localstack for Edge Lambda development; [it is not yet implemented](https://github.com/localstack/localstack/issues/5483)

---

## HOWTO

- From the root of this repository;

>[!TIP]
> TLDR;
>```bash
>  $ make localstack-up
>  $ make localstack-lambda
>  $ make localstack-cloudfront
>  $ make docker-run-authz
>  ```

- We are going to hook into localstack's boot process.
- We'll be initializing base services like S3, CloudFront, and ECR.
- We'll also be creating IAM roles and policies for our Lambda function.
- From there, we can get Lambda and Authz to talk to each other over the local Docker network.

### Create an S3 bucket and upload an image

- Let's get some files onto S3.

```bash
$ awslocal s3 mb \
    "s3://${S3_BUCKET_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}"

$ awslocal s3 cp \
    "${FILE}" \
    "s3://${S3_BUCKET_NAME}/${S3_KEY_NAME}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}"

# ensure this file is accessible
# http://localhost:4566/froch/this-is-fine.gif
```

### Interlude: System DNS configuration

We will need to MacGyver a DNS config to front our localstack S3 bucket with localstack CloudFront.

- Become familiar with [how localstack resolves DNS names](https://docs.localstack.cloud/user-guide/tools/dns-server).
- More specifically, review [how to use the System DNS host](https://docs.localstack.cloud/user-guide/tools/dns-server/#system-dns-configuration) in conjunction with localstack's DNS server.
- TLDR; Let's use port `5053`, out of an abundance of caution.

```bash
$ vi /etc/resolv.conf
nameserver 127.0.0.1:5053
```

```bash
$ docker-compose up localstack
$ dig test.localhost.localstack.cloud @127.0.0.1 -p 5053
;; ANSWER SECTION:
test.localhost.localstack.cloud. 300 IN	A	127.0.0.1
```

### Front the S3 bucket with CloudFront

- CloudFront on localstack requires a [PRO subscription](https://www.localstack.cloud/pricing).
- Fine, so be it. They had to find a monetization scheme somewhere; their tooling is excellent.
- All subsequent steps assume you have a `LOCALSTACK_AUTH_TOKEN` defined in your env.

```bash
$ awslocal cloudfront create-distribution \
    --origin-domain-name "${CLOUDFRONT_S3_ORIGIN}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
    
# ensure this file is accessible
# http://${distribution-id}.cloudfront.localhost.localstack.cloud:4566/this-is-fine.gif
```

### Create some ECR repositories

- ECR on localstack also requires a [PRO subscription](https://www.localstack.cloud/pricing).
- Alright, alright, alright.

```bash
$ awslocal ecr create-repository \
    --repository-name "${repo}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}")
```

### Create IAM roles and policies

- For our Lambda function to access things, we need to grant it the necessary permissions.
- Our bootstrap scripts will handle this.

- First, let's create a role which Lambda can assume.
```bash
$ awslocal iam create-role \
    --role-name "${AWS_IAM_LAMBDA_ROLE_NAME}" \
    --assume-role-policy-document "${AWS_IAM_LAMBDA_TRUST_POLICY_JSON}")
```

- Let's grant it pull access from ECR
```bash
$ awslocal iam create-policy \
      --policy-name "${AWS_IAM_LAMBDA_ECR_POLICY_NAME}" \
      --policy-document "${AWS_IAM_LAMBDA_ECR_POLICY_JSON}"
$ awslocal iam attach-role-policy \
      --role-name "${AWS_IAM_LAMBDA_ROLE_NAME}" \
      --policy-arn "arn:aws:iam::000000000000:policy/${AWS_IAM_LAMBDA_ECR_POLICY_NAME}"
```

- And let's also allow it to write to CloudWatch logs
```bash
$ awslocal iam create-policy \
      --policy-name "${AWS_IAM_LAMBDA_LOGS_POLICY_NAME}" \
      --policy-document "${AWS_IAM_LAMBDA_LOGS_POLICY_JSON}"
$ awslocal iam attach-role-policy \
      --role-name "${AWS_IAM_LAMBDA_ROLE_NAME}" \
      --policy-arn "arn:aws:iam::000000000000:policy/${AWS_IAM_LAMBDA_LOGS_POLICY_NAME}"
````

- Sweet! Our localstack initialization is complete.

### Build and deploy the Lambda function

- First, the TLDR;
```bash
$ make localstack-lambda
```
- Here's what that does.
```bash
$ docker compose build lambda
$ docker compose push lambda
$ awslocal lambda create-function \
    --function-name "${AWS_LAMBDA_NAME}" \
    --package-type Image \
    --code ImageUri="${AWS_LAMBDA_IMAGE}" \
    --role "${AWS_LAMBDA_ROLE}" \
    --handler "${AWS_LAMBDA_HANDLER}" \
    --endpoint-url "${AWS_LOCAL_ENDPOINT_URL}" \
    --region "${AWS_LOCAL_REGION}"
```

### Configure CloudFront to trigger the Lambda

- With everything in place, we need to reconfigure the deployed Cloudfront distribution to trigger the Lambda function.

```bash
$ make localstack-cloudfront
```

- In more detail; to update CloudFront, we can't just update parts of it through the API.
- We have to fetch the full current CloudFront distro's config, along with its current ETag.
- We then merge the chunks of config we want to update with the rest of the existing config.
- Only then, can we call the `update-distribution` API with the full config, providing the ETag as proof.

### Run the authz server in localhost docker

- First, the TLDR;
```bash
$ make docker-run-authz
```

- The internals of localstack run on the same bridged host network as regular containers.
- Nifty, they can see and talk to each other.
- This goes for all container runners in localstack: Lambda, ECS, EKS, etc.
