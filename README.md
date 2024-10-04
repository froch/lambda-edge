# Lambda@Edge SSO POC

<div style="text-align: center;">
  <img src="https://github.com/froch/lambda-edge/blob/main/tools/assets/aws-architectture.png?raw=true" alt="AWS Architecture">
</div>

---

>[!TIP]
> TLDR;
>```bash
>  $ make localstack-up
>  $ make localstack-lambda
>  $ make localstack-cloudfront
>  $ make docker-run-authz
>  ```

---

## Source Material

- [Whitepaper (2023)](https://aws.amazon.com/blogs/networking-and-content-delivery/external-server-authorization-with-lambdaedge/)
- [Lambda@Edge product page](https://aws.amazon.com/lambda/edge/)
- [Lambda@Edge developer guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html) 

## Major Goals
- Secure CloudFront content distribution using external server Authz.
- Dockerize the Lambda@Edge function and the Authz server.
- Translate the working local config to Terraform HCL.

---

## Project Structure

```
├── .localstack
├── authz
├── lambda
├── terraform
└── tools
```

- **.localstack**: Config and volumes for [localstack](https://docs.localstack.cloud/user-guide/aws/lambda/)
- **authz**: A simple golang webserver with which to iterate on requests and responses.
- **lambda**: Typescript code for the Lambda@Edge function described in the whitepaper.
- **terraform**: Terraform HCL configuration files to provision AWS resources.
- **tools**: Scripts and helpers for the above.

---

## Plan of Attack

### 1. Build the Lambda@Edge Function and the Authz server
- Build the Typescript Lambda@Edge function that forwards requests to an external server for authorization.
- Create an S3 bucket whose contents we want to protect.
- Write a simple, surrogate Authz server to build out behavior.
- Bonus points for localhost encryption for data in transit.

### 2. Build the Docker images
- Package the Lambda@Edge function into a Docker container, using the AWS runtime image.
- Build the Authz Docker image.
- Run the Lambda container in localstack and ensure it communicates with Authz.

### 3. Local Iteration
- Add a file to the localstack S3 bucket, ensure it's unprotected.
- Front the localstack S3 bucket with localstack's CloudFront.
- Ensure the file remains accessible.
- Iterate on the Lambda@Edge function and Authz server until we can toggle between protected and unprotected states.

### 4. AWS Deployment / POC
- Translate the localstack configs to their big-brother AWS representations with Terraform HCL.
- Create a temporary S3 bucket, so we don't leak anything during initial setup.
- Upload the gif to the bucket.
- Front the S3 bucket with a CloudFront distribution.
- Deploy the Lambda@Edge function.
- Deploy the surrogate Authz server.
- Ensure the gif is protected by the Lambda@Edge function.

### 5. AWS Deployment / The Real Deal
- Modify the Lambda@Edge function to use the real Authz server.
- Ensure the gif is protected by the Lambda@Edge function.
- Modify the install to use the real S3 bucket and CloudFront distributions.
- Ensure the real content is protected by the Lambda@Edge function.
- ... ?
- Drinks are on me.

---

## HOWTO

- Most of these steps are taken care of during localstack boot.
- We won't need to run all these commands, but we include them here for reference.
- Also, take a peek at the `Makefile`; it is our friend.

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
- And let's also allow it to write to CloudaWatch logs
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

### Run the authz server in localhost docker

- First, the TLDR;
```bash
$ make docker-run-authz
```

- The internals of localstack run on the same bridged host network
- Thus, they can resolve containers running on the host.
- As such, the authz server is visible to Lambda, ECS, EKS, etc.
