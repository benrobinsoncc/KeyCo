import type { VercelRequest, VercelResponse } from '@vercel/node';

interface ChatRequest {
  query: string;
}

export default async function handler(
  request: VercelRequest,
  response: VercelResponse,
) {
  // Only allow POST requests
  if (request.method !== 'POST') {
    return response.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { query } = request.body as ChatRequest;

    // Validate input
    if (!query || typeof query !== 'string' || query.trim().length === 0) {
      return response.status(400).json({ error: 'Query is required' });
    }

    // Get API key from environment variable
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.error('OPENAI_API_KEY not configured');
      return response.status(500).json({ error: 'Server configuration error' });
    }

    // Call OpenAI API
    const openAIResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4',
        messages: [
          { role: 'user', content: query }
        ],
        max_tokens: 500,
      }),
    });

    if (!openAIResponse.ok) {
      const errorData = await openAIResponse.json().catch(() => ({}));
      console.error('OpenAI API error:', errorData);
      return response.status(500).json({ 
        error: 'Failed to generate response',
        details: errorData.error?.message || 'Unknown error'
      });
    }

    const data = await openAIResponse.json();

    // Extract the response text
    if (data.choices && data.choices[0] && data.choices[0].message) {
      const responseText = data.choices[0].message.content.trim();
      return response.status(200).json({ text: responseText });
    }

    return response.status(500).json({ error: 'Invalid response from AI' });

  } catch (error: any) {
    console.error('Error in chat handler:', error);
    return response.status(500).json({ 
      error: 'Internal server error',
      details: error.message 
    });
  }
}

