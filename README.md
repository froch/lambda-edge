# Lambda@Edge SSO POC

<div style="text-align: center;">
  <img src="./tools/assets/aws-architecture.png" alt="AWS Architecture">
</div>

## Source Material

- [Whitepaper (2023)](https://aws.amazon.com/blogs/networking-and-content-delivery/external-server-authorization-with-lambdaedge/)
- [Lambda@Edge product page](https://aws.amazon.com/lambda/edge/)
- [Lambda@Edge developer guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html) 

## Major Goals
- Secure CloudFront content distribution using external server Authz.
- Dockerize the Lambda@Edge function and the Authz server.
- Translate the working local config to Terraform HCL.

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

## Plan of Attack

### 1. Build the Lambda@Edge Function and the Authz server
- Build the Typescript Lambda@Edge function that forwards requests to an external server for authorization.
- Create an S3 bucket whose contents we want to protect.
- Write a simple, surrogate Authz server to build out behavior.
- Bonus points for localhost encryption for data in transit.

### 2. Build the Docker images
- Package the Lambda@Edge function into a Docker container, using the AWS runtime image.
- Build the Authz Docker image.
- Run the Lambda container in localstack and ensure it communicates with Authz over DinD (Docker in Docker).

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

## HOWTO 

### Create an S3 bucket and upload an image

```bash
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
