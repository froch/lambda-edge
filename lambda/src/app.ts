import { APIGatewayProxyHandler } from 'aws-lambda';
import https from 'https';
import AWS from 'aws-sdk';

const s3 = new AWS.S3({
  endpoint: 'http://localstack:4566',
  s3ForcePathStyle: true, // localstack requirement
});

const AUTHZ_HTTP_200 = 'https://external-server/200';
const AUTHZ_HTTP_403 = 'https://external-server/403';

const keepAliveAgent = new https.Agent({ keepAlive: true });

// HTML content for the error response
const errorContent = `
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Authentication Error</title>
  </head>
  <body>
    <p>Authentication Error</p>
  </body>
</html>
`;

export const handler: APIGatewayProxyHandler = async (event, _context) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;
  let authHeader = '';

  if (headers['authentication']) {
    authHeader = headers['authentication'][0].value;
  } else {
    return {
      statusCode: 403,
      body: 'Authentication header missing',
    };
  }

  try {
    const isAuthorized = await authorizeWithExternalServer(authHeader);

    if (isAuthorized) {
      return request; // forward to S3
    } else {
      return {
        status: '403',
        statusDescription: 'Forbidden',
        body: errorContent,
        headers: {
          'content-type': [{ key: 'Content-Type', value: 'text/html' }],
        },
      };
    }
  } catch (error) {
    console.error('Error during authorization or S3 interaction:', error);
    return {
      status: '500',
      statusDescription: 'Internal Server Error',
      body: 'An error occurred',
    };
  }
};


// Call the remote auth server
const authorizeWithExternalServer = (authHeader: string): Promise<boolean> => {
  return new Promise((resolve, reject) => {
    options := {
      port: 443,
      path: '/auth-check',
      method: 'GET',
      headers: {
        'authentication': authHeader
      },
      agent: keepAliveAgent
    };

    if

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(true);
        } else {
          resolve(false);
        }
      });
    });

    req.on('error', (error) => {
      console.error('Error contacting external auth server:', error);
      reject(error);
    });

    req.end();
  });
};
