import type { VercelRequest, VercelResponse } from '@vercel/node';

/**
 * Health check endpoint for monitoring backend availability
 * Returns 200 OK if backend is healthy, useful for monitoring and circuit breaker logic
 */
export default async function handler(
  request: VercelRequest,
  response: VercelResponse,
) {
  // Allow GET and HEAD requests
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    return response.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Check if OpenAI API key is configured
    const apiKey = process.env.OPENAI_API_KEY;
    const isHealthy = !!apiKey && apiKey.length > 0;

    if (isHealthy) {
      return response.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        services: {
          openai: 'configured'
        }
      });
    } else {
      return response.status(503).json({
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        services: {
          openai: 'not_configured'
        }
      });
    }
  } catch (error: any) {
    console.error('Health check error:', error);
    return response.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
}

