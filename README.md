# Lambda@Edge Authorization POC

## Overview
This project implements a proof-of-concept (POC) for authorizing requests to Amazon CloudFront using a Lambda@Edge function.

The funciton will forward authorization data to an external server. The setup mimics a real-world scenario where content is served from CloudFront, while existing authorization mechanisms remain intact.

## Goals
- Secure CloudFront content distribution using header-based external server authorization.
- Dockerize the Lambda@Edge function to ensure it can be easily tested and deployed.
- Implement infrastructure as code (IaC) with Terraform to provision CloudFront, Lambda@Edge, and related AWS resources.

## Project Structure

```
├── docker
├── infrastructure
├── lambda
└── scripts
```

- **docker/**: Docker setup for building and testing the Lambda function locally.
- **infrastructure/**: Contains Terraform configurations for AWS resources.
- **lambda/**: Node.js code for the Lambda@Edge function to handle external authorization.
- **scripts/**: Utility scripts for deployment and testing.

## Plan of Attack

### 1. Infrastructure Setup (Terraform)
- Set up a CloudFront distribution with an S3 origin.
- Configure Lambda@Edge function to trigger on the Viewer-Request event.
- Provision an external authorization server using a simple PHP server.
- Define networking rules and security policies to ensure secure communication between the external server and Lambda@Edge.

### 2. Lambda@Edge Dockerization
- Write a Node.js Lambda function that handles authentication and forwards requests to the external server.
- Dockerize the Lambda function to test it locally before deployment.
- Ensure the Docker image is compatible with AWS Lambda container requirements.

### 3. Deployment & Testing
- Use Terraform to deploy the CloudFront distribution, Lambda@Edge function, and external server.
- Test the setup by sending valid and invalid authorization headers.
- Monitor logs and output using AWS CloudWatch for debugging and optimization.
