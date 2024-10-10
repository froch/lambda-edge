import {
  CloudFrontRequestEvent,
  CloudFrontRequestCallback,
  CloudFrontRequestResult,
} from 'aws-lambda';
import fs from 'fs';
import https from 'https';
import path from 'path';
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

// -------- HTML response when authz fails -------- //

const NOPE_HTML = `
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

// -------- main handler -------- //

// handler is the main lambda entrypoint
export const handler = (
  event: CloudFrontRequestEvent,
  context: any,
  callback: CloudFrontRequestCallback
): void => {
  try {
    console.log('Event:', JSON.stringify(event));
    console.log('Context:', JSON.stringify(context));
    console.log('Callback:', JSON.stringify(callback));

    const request = _isValidEvent(event);
    const authzHeader = _getAuthzHeader(request.headers);

    if (!authzHeader) {
      return callback(null, _writeOut(403, 'Authz: NOPE', NOPE_HTML));
    }

    let secretValue = '';

    getSecretOIDC((secret, error) => {
      if (error) {
          console.log("failed to fetch OIDC secret: ", error);
          return callback(null, _writeOut(500, 'Internal Server Error', 'An internal error occurred.'));
      }

      console.log("OIDC secret fetched successfully");
      secretValue = secret ?? '';

      authzExternal(authzHeader, secretValue, (_authOK, _statusCode) => {
        if (_authOK) {
          console.log('Authz: OK');
          return callback(null, request);
        } else {
          console.log('Authz: NOPE');
          return callback(null, _writeOut(_statusCode, 'Authz: NOPE', NOPE_HTML));
        }
      });
    });
  } catch (error) {
    console.error('Handler error:', error instanceof Error ? error.message : error);
    return callback(null, _writeOut(500, 'Internal Server Error', 'An internal error occurred.'));
  }
};

// -------- external authz call -------- //

// getSecretOIDC retrieves our OIDC token from AWS Secrets Manager
// we need to fetch this first, and then call the authzServer
const getSecretOIDC = (callback: (secret: string | null, error: Error | null) => void): void => {
  const { AWS_REGION, AWS_SECRET_ARN_OIDC } = _loadConfigs();
  const command = new GetSecretValueCommand({ SecretId: AWS_SECRET_ARN_OIDC });
  const secretsManagerClient = new SecretsManagerClient({ region: AWS_REGION });

  secretsManagerClient.send(command, (error, response) => {
    console.log('secretsmanager error:', JSON.stringify(error));
    console.log('secretsmanager response:', JSON.stringify(response));
    if (error) {
      return callback(null, error);
    }
    if (response && response.SecretString) {
      return callback(response.SecretString, null);
    }
    return callback(null, new Error('SecretString not found in secret'));
  });
};

// authzExternal calls the external authorization server
const authzExternal = (
  authzHeader: string,
  secretValue: string,
  callback: (_authOK: boolean, _statusCode: number) => void
): void => {
  const { AUTHZ_HOST, AUTHZ_PORT, AUTHZ_PATH, KEEP_ALIVE_TIMEOUT } = _loadConfigs();
  const options = {
    hostname: AUTHZ_HOST,
    port: AUTHZ_PORT,
    path: AUTHZ_PATH,
    method: 'GET',
    headers: {
      Authorization: authzHeader,
    },
    timeout: KEEP_ALIVE_TIMEOUT,
  };

  const req = https.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    res.on('end', () => {
      console.log('Authorization OK: ', data);
      callback(res.statusCode === 200, res.statusCode ?? 500);
    });
  });
  req.on('error', (error: any) => {
    console.error('Authorization error: ', error.message);
    callback(false, 500);
  });
  req.end();
};

// -------- internals -------- //

// _isValidEvent checks the incoming event structure
const _isValidEvent = (event: CloudFrontRequestEvent) => {
  if (!event.Records || event.Records.length === 0 || !event.Records[0].cf) {
    throw new Error(`Invalid event structure: ${JSON.stringify(event)}`);
  }
  return event.Records[0].cf.request;
};

// _getAuthzHeader extracts the Authorization header from the request
const _getAuthzHeader = (headers: Record<string, any>) => {
  const headerKey = Object.keys(headers).find((key) => key.toLowerCase() === 'authorization');
  return headerKey ? headers[headerKey][0]?.value : undefined;
};

// _loadConfigs loads the configuration from a config.json file, or falls back to defaults
// lambda@edge does not allow custom environment variables
const _loadConfigs = () => {
  const DEFAULT_AUTHZ_VALUES = {
    AUTHZ_HOST: process.env.AUTHZ_HOST || 'authz',
    AUTHZ_PORT: process.env.AUTHZ_PORT || '8080',
    AUTHZ_PATH: process.env.AUTHZ_PATH || '/authz',
    AWS_REGION: process.env.AWS_REGION || 'us-east-1',
    AWS_SECRET_ARN_OIDC: process.env.AWS_SECRET_ARN_OIDC || '',
    KEEP_ALIVE_TIMEOUT: 5000,
  };

  const configPath = path.resolve(__dirname, 'config.json');
  if (!fs.existsSync(configPath)) {
    console.log(`${configPath} not found.`);
    return DEFAULT_AUTHZ_VALUES;
  }

  try {
    const configData = fs.readFileSync(configPath, 'utf8');
    return JSON.parse(configData);
  } catch (error) {
    console.error('failed loading config:', error);
    return DEFAULT_AUTHZ_VALUES;
  }
};

// _writeOut returns a CloudFrontRequestResult object
const _writeOut = (
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
