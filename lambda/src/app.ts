import {
  CloudFrontRequestEvent,
  CloudFrontRequestCallback,
  CloudFrontRequestResult,
} from 'aws-lambda';
import axios from 'axios';
import https from 'https';

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

export const handler = (
  event: CloudFrontRequestEvent,
  context: any,
  callback: CloudFrontRequestCallback
): void => {
  try {
    const request = validateEventStructure(event);
    const authHeader = getAuthenticationHeader(request.headers);

    if (!authHeader) {
      return callback(null, generateErrorResponse(403, 'Authz: NOPE', AUTH_ERROR_HTML));
    }

    authzWithExternalServer(authHeader, (isAuthorized, statusCode) => {
      if (isAuthorized) {
        return callback(null, request);
      } else {
        return callback(null, generateErrorResponse(statusCode, 'Authz: NOPE', AUTH_ERROR_HTML));
      }
    });
  } catch (error) {
    console.error('Handler error:', error instanceof Error ? error.message : error);
    return callback(
      null,
      generateErrorResponse(500, 'Internal Server Error', 'An internal error occurred.')
    );
  }
};

const authzWithExternalServer = (
  authzHeader: string,
  callback: (isAuthorized: boolean, statusCode: number) => void
): void => {
  const AUTHZ_HOST = process.env.AUTHZ_HOST || 'authz';
  const AUTHZ_PORT = process.env.AUTHZ_PORT || '8080';
  const AUTHZ_PATH = process.env.AUTHZ_PATH || '/authz';
  const KEEP_ALIVE_TIMEOUT = parseInt(process.env.KEEP_ALIVE_TIMEOUT || '5000', 10);

  const agent = new https.Agent({ keepAlive: true, timeout: KEEP_ALIVE_TIMEOUT });

  axios
    .get(`https://${AUTHZ_HOST}:${AUTHZ_PORT}${AUTHZ_PATH}`, {
      headers: { Authorization: authzHeader },
      httpsAgent: agent,
      timeout: KEEP_ALIVE_TIMEOUT,
    })
    .then((response) => {
      callback(response.status === 200, response.status);
    })
    .catch((error) => {
      const statusCode = error.response ? error.response.status : 500;
      console.error('Authorization request error:', error instanceof Error ? error.message : error);
      callback(false, statusCode);
    });
};

const validateEventStructure = (event: CloudFrontRequestEvent) => {
  console.log('Event:', JSON.stringify(event));
  if (!event.Records || event.Records.length === 0 || !event.Records[0].cf) {
    throw new Error(`Invalid event structure: ${JSON.stringify(event)}`);
  }
  return event.Records[0].cf.request;
};

const getAuthenticationHeader = (headers: Record<string, any>) => {
  console.log('Headers:', JSON.stringify(headers));
  const headerKey = Object.keys(headers).find((key) => key.toLowerCase() === 'authorization');
  return headerKey ? headers[headerKey][0]?.value : undefined;
};

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
