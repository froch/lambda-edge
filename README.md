# Lambda@Edge SSO POC

<div style="text-align: center;">
  <img src="./tools/assets/aws-architecture.png" alt="AWS Architecture">
</div>

## Source Material

- [Whitepaper (2023)](https://aws.amazon.com/blogs/networking-and-content-delivery/external-server-authorization-with-lambdaedge/)
- [Lambda@Edge product page](https://aws.amazon.com/lambda/edge/)
- [Lambda@Edge developer guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html)
- 

## Major Goals
- Secure CloudFront content distribution using external server Authz.
- Dockerize the Lambda@Edge function and the Authz server.
- Translate the working local config to Terraform HCL.

## Project Structure

```
├── authz
├── infrastructure
├── lambda
└── tools
```

- **.localstack**: Config files for [localstack](https://docs.localstack.cloud/user-guide/aws/lambda/), a local AWS cloud stack for breaking things.
- **authz**: A simple golang webserver with which to iterate on requests and responses.
- **infrastructure**: Terraform HCL configuration files to provision AWS resources.
- **lambda**: Typescript code for the Lambda@Edge function described in the whitepaper.
- **tools**: Scripts and helpers for the above

## Plan of Attack

### 1. Building the Lambda@Edge Function and the Authz server
- Build the Typescript Lambda@Edge function that forwards requests to an external server for authorization.
- Create an S3 bucket whose contents we want to protect.
- Write a simple, surrogate Authz server to build out behavior
- Bonus points for localhost encryption for data in transit

### 2. Building the Docker images
- Package the Lambda@Edge function into a Docker container, using the AWS runtime image.
- Build the Authz Docker image.
- Run the Lambda container in localstack and ensure it communicates with Authz over DinD (Docker in Docker)

### 3. Deployment & Testing
- Add a file to the localstack S3 bucket, ensure it's unprotected.
- Front the localstack S3 bucket with localstack's CloudFront
- Ensure the file remains accessible
- Iterate on the Lambda@Edge function and Authz server until we can toggle between protected and unprotected states
- Translate the local configs to their big-brother AWS resource representations with Terraform HCL

## HOWTO 

### Create an S3 bucket and upload an image
[infrastructure](infrastructure)
