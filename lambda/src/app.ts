import { CloudFrontRequestEvent, CloudFrontRequestCallback, CloudFrontRequestResult } from 'aws-lambda';
import https, { RequestOptions } from 'https';
import { IncomingMessage } from 'http';

const keepAliveAgent = new https.Agent({ keepAlive: true, timeout: 5000 });

const AUTH_ERROR_HTML = `
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Authz: NOPE</title>
  </head>
  <body>
    <p>That's a Texas-Size NOPE from me, dawg.</p>
  </body>
</html>
`;

const EXTERNAL_SERVER_HOSTNAME = 'external-server.com';
const AUTHORIZATION_PATH = '/auth-check';

export const handler = async (
    event: CloudFrontRequestEvent,
    context: any,
    callback: CloudFrontRequestCallback
): Promise<void> => {

  const request = event.Records[0].cf.request;
  const headers = request.headers;

  try {
    const authHeader = headers['authentication']?.[0]?.value || '';

    if (!authHeader) {
      return callback(null, generateErrorResponse(403, 'Authz: NOPE', AUTH_ERROR_HTML));
    }

    const isAuthorized = await authzWithExternalServer(authHeader);

    if (isAuthorized) {
      return callback(null, request);
    } else {
      return callback(null, generateErrorResponse(403, 'Authz: NOPE', AUTH_ERROR_HTML));
    }
  } catch (error) {
    console.error('Authorization error:', error);
    return callback(null, generateErrorResponse(500, 'Internal Server Error', 'An internal error occurred.'));
  }
};

// Call the external Authz server
const authzWithExternalServer = (
    authHeader: string
): Promise<boolean> => {

  return new Promise((resolve, reject) => {
    const options: RequestOptions = {
      hostname: EXTERNAL_SERVER_HOSTNAME,
      port: 443,
      path: AUTHORIZATION_PATH,
      method: 'GET',
      headers: { 'authentication': authHeader },
      agent: keepAliveAgent,
      timeout: 5000,
    };

    const req = https.request(options, (res: IncomingMessage) => {
      let data = '';

      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(true);
        } else {
          resolve(false);
        }
      });
    });

    req.on('error', (error) => {
      console.error('Authz failed:', error);
      reject(error);
    });

    req.on('timeout', () => {
      console.error('Authz request timed out.');
      req.abort();
      reject(new Error('Authz request timed out.'));
    });

    req.end();
  });
};

// Generate a CloudFront-compatible error response
const generateErrorResponse = (
    status: number,
    statusDescription: string,
    body: string
): CloudFrontRequestResult => {

  return {
    status: status.toString(),
    statusDescription,
    body,
    headers: {
      'content-type': [{ key: 'Content-Type', value: 'text/html' }],
      'cache-control': [{ key: 'Cache-Control', value: 'no-store' }],
    },
  };
};
