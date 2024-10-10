# Lambda@Edge SSO POC

<div style="text-align: center;">
  <img src="https://github.com/froch/lambda-edge/blob/main/tools/assets/aws-architectture.png?raw=true" alt="AWS Architecture">
</div>

---

## Source Material

- [Whitepaper (2023)](https://aws.amazon.com/blogs/networking-and-content-delivery/external-server-authorization-with-lambdaedge/)
- [Lambda@Edge developer guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html) 
- [AWS samples](https://github.com/aws-samples/cloudfront-authorization-at-edge)

## Major Goals
- Secure CloudFront content distribution using external server Authz.
- Dockerize the Lambda@Edge function and the Authz server.
- Translate the working local config to Terraform HCL.

---

## Project Structure

```
├── .localstack
├── authz
├── docs
├── lambda
├── terraform
└── tools
```

- **.localstack**: Config and volumes for [localstack](https://docs.localstack.cloud/user-guide/aws/lambda/)
- **authz**: A simple golang webserver with which to iterate on requests and responses.
- **docs**: Documentation about this project.
- **lambda**: Typescript code for the Edge Lambda function described in the [Whitepaper](https://aws.amazon.com/blogs/networking-and-content-delivery/external-server-authorization-with-lambdaedge/).
- **terraform**: Terraform HCL configuration files to provision AWS resources.
- **tools**: Scripts and helpers for the above.

---

## Documentation

- [Authz Server](docs/authz.md)
- [Edge Lambda](docs/edgelambda.md)
- [localstack](docs/localstack.md)

---

## Plan of Attack

### [🔥] 1. Build the Lambda@Edge Function and the Authz server 
- [🔥] Build the Typescript Lambda@Edge function that forwards requests to an external server for authorization.
- [🔥] Create an S3 bucket whose contents we want to protect.
- [🔥] Write a simple, surrogate Authz server to build out behavior.
- [🔥] Bonus points for localhost encryption of data in transit.

### [🔥] 2. Build the Docker images
- [🔥] Package the Lambda@Edge function into a Docker container, using the AWS runtime image.
- [🔥] Build the Authz Docker image.
- [🔥] Run the Lambda container in localstack and ensure it communicates with Authz.
- [💧] Edge Lambda restriction: it cannot run Docker images, we must rely on zip packages.

### [🔥] 3. Local Iteration
- [🔥] Add a file to the localstack S3 bucket, ensure it's unprotected.
- [🔥] Front the localstack S3 bucket with localstack's CloudFront.
- [🔥] Ensure the file remains accessible.
- [🔥] Iterate on the Lambda@Edge function and Authz server until we can toggle between protected and unprotected states.
- [💧] While localstack is excellent and a valuable tool, for our immediate purposes [edgelambde is not yet implemented](https://github.com/localstack/localstack/issues/5483).

### [🔥] 4. AWS Deployment / POC
- [🔥] Translate the localstack configs to their big-brother AWS representations with Terraform HCL.
- [🔥] Create a temporary S3 bucket, so we don't leak anything during initial setup.
- [🔥] Upload the gif to the bucket.
- [🔥] Front the S3 bucket with a CloudFront distribution.
- [🔥] Deploy the Lambda@Edge function.
- [🔥] Deploy the surrogate Authz server.
- [🔥] Ensure the gif is protected by the Lambda@Edge function.

### 5. AWS Deployment / The Real Deal
- Modify the Lambda@Edge function to use the real Authz server.
- Ensure the gif is protected by the Lambda@Edge function.
- Modify the install to use the real S3 bucket and CloudFront distributions.
- Ensure the real content is protected by the Lambda@Edge function.
- ... ?
- Drinks are on me.

