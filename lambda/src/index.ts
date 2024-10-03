import { APIGatewayProxyHandler } from 'aws-lambda';
import axios from 'axios';

export const handler: APIGatewayProxyHandler = async (event, context) => {
  const { headers } = event;
  const authHeader = headers['authentication'];
  console.log(context);

  if (!authHeader) {
    return {
      statusCode: 403,
      body: 'Authentication header missing',
    };
  }

  try {
    const response = await axios.get('<external-auth-server>', {
      headers: {
        authentication: authHeader,
      },
    });

    if (response.status === 200) {
      return {
        statusCode: 200,
        body: 'Authorized',
      };
    } else {
      return {
        statusCode: 403,
        body: 'Unauthorized',
      };
    }
  } catch (error) {
    console.error('Error while authorizing:', error);
    return {
      statusCode: 500,
      body: 'Internal Server Error',
    };
  }
};
