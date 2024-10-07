import { CloudFrontRequestEvent, CloudFrontRequestCallback, CloudFrontRequestResult } from 'aws-lambda';
import https, { RequestOptions } from 'https';
import { IncomingMessage } from 'http';

const AUTHZ_HOST = process.env.AUTHZ_HOST || 'authz';
const AUTHZ_PORT = process.env.AUTHZ_PORT || '8080';
const AUTHZ_PATH = process.env.AUTHZ_PATH || '/authz';
const KEEP_ALIVE_TIMEOUT = parseInt(process.env.KEEP_ALIVE_TIMEOUT || '5000', 10);

const keepAliveAgent = new https.Agent({ keepAlive: true, timeout: KEEP_ALIVE_TIMEOUT });

const AUTH_ERROR_HTML = `
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Authz: NOPE</title>
  </head>
  <body>
    <p>That's a Texas-size NOPE from me, dawg.</p>
  </body>
</html>
`;

export const handler = (event: CloudFrontRequestEvent, context: any, callback: CloudFrontRequestCallback): void => {
  try {
    const request = validateEventStructure(event);
    const authHeader = getAuthenticationHeader(request.headers);

    if (!authHeader) {
      return callback(null, generateErrorResponse(403, 'Authz: NOPE', AUTH_ERROR_HTML));
    }

    authzWithExternalServer(authHeader)
        .then((isAuthorized) => {
          if (isAuthorized) {
            return callback(null, request);
          } else {
            return callback(null, generateErrorResponse(403, 'Authz: NOPE', AUTH_ERROR_HTML));
          }
        })
        .catch((error) => {
          console.error('Authorization error:', error);
          return callback(null, generateErrorResponse(500, 'Internal Server Error', 'An internal error occurred.'));
        });
  } catch (error) {
    console.error('Handler error:', error);
    return callback(null, generateErrorResponse(500, 'Internal Server Error', 'An internal error occurred.'));
  }
};

const authzWithExternalServer = (authzHeader: string): Promise<boolean> => {
  return new Promise((resolve, reject) => {
    const options: RequestOptions = {
      hostname: AUTHZ_HOST,
      port: AUTHZ_PORT,
      path: AUTHZ_PATH,
      method: 'GET',
      headers: { 'Authorization': authzHeader },
      agent: keepAliveAgent,
      timeout: KEEP_ALIVE_TIMEOUT,
    };

    const req = https.request(options, (res: IncomingMessage) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        res.statusCode === 200 ? resolve(true) : resolve(false);
      });
    });

    req.on('error', (error) => {
      console.error('Authorization request error:', error);
      reject(error);
    });

    req.on('timeout', () => {
      console.error('Authorization request timed out.');
      req.abort();
      reject(new Error('Authorization request timed out.'));
    });

    req.end();
  });
};

const validateEventStructure = (event: CloudFrontRequestEvent) => {
  if (!event.Records || event.Records.length === 0 || !event.Records[0].cf) {
    throw new Error(`Invalid event structure: ${JSON.stringify(event)}`);
  }
  return event.Records[0].cf.request;
};

const getAuthenticationHeader = (headers: Record<string, any>) => {
  return headers['authentication'] && headers['authentication'][0]?.value;
};

const generateErrorResponse = (status: number, statusDescription: string, body: string): CloudFrontRequestResult => {
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
