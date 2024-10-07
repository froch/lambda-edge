import { describe, it, expect, beforeAll } from 'vitest';
import { handler } from './app';
import { CloudFrontRequestEvent } from 'aws-lambda';
import dotenv from 'dotenv';

const mockRequest = (headers = {}) =>
  ({
    Records: [
      {
        cf: {
          request: {
            headers,
          },
        },
      },
    ],
  }) as CloudFrontRequestEvent;

const mockResponseCallback = () => {
  const res: { result: any | null } = { result: null };
  const callback = (_error: any, result: any) => {
    res.result = result;
  };
  return { callback, res };
};

describe('Lambda Authorization Handler with Real External Server', () => {
  if ( // load .env file if not already loaded
    process.env.AUTHZ_HOST === undefined ||
    process.env.AUTHZ_PORT === undefined ||
    process.env.AUTHZ_PATH === undefined
  ) {
    dotenv.config();
  }

  // stash these for later
  const validAuthzHeader = process.env.AUTHZ_HEADER || undefined;
  const AUTHZ_HOST = process.env.AUTHZ_HOST;
  const AUTHZ_PORT = process.env.AUTHZ_PORT;
  const AUTHZ_PATH = process.env.AUTHZ_PATH;

  beforeAll(() => {
    // reset on every run
    process.env.AUTHZ_HOST = AUTHZ_HOST;
    process.env.AUTHZ_PORT = AUTHZ_PORT;
    process.env.AUTHZ_PATH = AUTHZ_PATH;
  });

  it('should return 403 if authentication header is missing', async () => {
    const { callback, res } = mockResponseCallback();
    const event = mockRequest({});

    handler(event, {}, callback);
    if (!res.result) throw new Error('No result returned');

    expect(res.result.status).toBe('403');
    expect(res.result.statusDescription).toBe('Authz: NOPE');
  });

  it('should return 403 if authentication header is incorrect', async () => {
    const { callback, res } = mockResponseCallback();
    const event = mockRequest({
      authorization: [{ value: 'wrong-authz' }],
    });

    await new Promise<void>((resolve) => {
      handler(event, {}, (...args) => {
        callback(...args);
        resolve();
      });
    });

    expect(res.result).not.toBeNull();
    expect(res.result.status).toBe('403');
    expect(res.result.statusDescription).toBe('Authz: NOPE');
  });

  it('should return 404 on invalid path', async () => {
    const { callback, res } = mockResponseCallback();
    const event = mockRequest({
      authorization: [{ value: validAuthzHeader }],
    });

    process.env.AUTHZ_PATH = '/invalid-path';

    await new Promise<void>((resolve) => {
      handler(event, {}, (...args) => {
        callback(...args);
        resolve();
      });
    });

    process.env.AUTHZ_PATH = '/authz';

    expect(res.result).not.toBeNull();
    expect(res.result.status).toBe('404');
  });

  it('should return 200 if authorization is successful', async () => {
    const { callback, res } = mockResponseCallback();
    expect(callback).toBeDefined();
    const event = mockRequest({
      authorization: [{ value: validAuthzHeader }],
    });

    await new Promise<void>((resolve, reject) => {
      handler(event, {}, (error, result) => {
        if (error) {
          return reject(error);
        }
        res.result = result;
        resolve();
      });
    });

    if (!res.result) throw new Error('No result returned');
    expect(res.result).toBe(event.Records[0].cf.request);
  });

  it('should return 500 on malformed event structure', async () => {
    const { callback, res } = mockResponseCallback();
    const malformedEvent = { Records: [] }; // No valid cf record

    handler(malformedEvent as any, {}, callback);
    if (!res.result) throw new Error('No result returned');

    expect(res.result.status).toBe('500');
    expect(res.result.statusDescription).toBe('Internal Server Error');
  });
});
