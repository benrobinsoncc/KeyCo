import type { VercelRequest, VercelResponse } from '@vercel/node';

interface RewriteRequest {
  text: string;
  tone: number; // 0-1, 0=casual, 1=formal
  length: number; // 0-1, 0=detailed, 1=brief
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
    const { text, tone, length } = request.body as RewriteRequest;

    // Validate input
    if (!text || typeof text !== 'string' || text.trim().length === 0) {
      return response.status(400).json({ error: 'Text is required' });
    }

    if (typeof tone !== 'number' || tone < 0 || tone > 1) {
      return response.status(400).json({ error: 'Tone must be between 0 and 1' });
    }

    if (typeof length !== 'number' || length < 0 || length > 1) {
      return response.status(400).json({ error: 'Length must be between 0 and 1' });
    }

    // Get API key from environment variable
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.error('OPENAI_API_KEY not configured');
      return response.status(500).json({ error: 'Server configuration error' });
    }

    // Build tone and length descriptions
    const toneDescription = getToneDescription(tone);
    const lengthDescription = getLengthDescription(length);
    const { maxWords, maxSentences } = getLengthConstraints(length);

    // Build prompt
    const prompt = `Rewrite the following message with STRICTLY the following requirements:

TONE: ${toneDescription}
LENGTH: ${lengthDescription}

CRITICAL CONSTRAINTS:
- Maximum word count: ${maxWords} words
- Maximum sentences: ${maxSentences}
- You MUST stay within these limits
- Do not include any explanations, just the rewritten message
- Preserve the core meaning and intent

Original message: ${text}

Rewritten message (strictly within limits):`;

    // Calculate max tokens
    const maxTokens = calculateMaxTokens(length);

    // Call OpenAI API
    const openAIResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: [
          { role: 'user', content: prompt }
        ],
        max_tokens: maxTokens,
      }),
    });

    if (!openAIResponse.ok) {
      const errorData = await openAIResponse.json().catch(() => ({}));
      console.error('OpenAI API error:', errorData);
      return response.status(500).json({ 
        error: 'Failed to generate rewrite',
        details: errorData.error?.message || 'Unknown error'
      });
    }

    const data = await openAIResponse.json();

    // Extract the rewritten text
    if (data.choices && data.choices[0] && data.choices[0].message) {
      const rewrittenText = data.choices[0].message.content.trim();
      return response.status(200).json({ text: rewrittenText });
    }

    return response.status(500).json({ error: 'Invalid response from AI' });

  } catch (error: any) {
    console.error('Error in rewrite handler:', error);
    return response.status(500).json({ 
      error: 'Internal server error',
      details: error.message 
    });
  }
}

function getToneDescription(value: number): string {
  if (value < 0.15) {
    return "very casual and friendly, use contractions like 'you're' and 'I'll', keep it conversational";
  } else if (value < 0.35) {
    return "friendly and warm, conversational but slightly more polished";
  } else if (value < 0.50) {
    return "professional yet approachable, balanced between friendly and formal";
  } else if (value < 0.70) {
    return "professional and clear, use standard business language";
  } else if (value < 0.85) {
    return "formal and professional, avoid contractions, use proper business etiquette";
  } else {
    return "very formal and professional, use formal language, avoid casual expressions entirely";
  }
}

function getLengthDescription(value: number): string {
  if (value < 0.20) {
    return "detailed and comprehensive - include all important points and context";
  } else if (value < 0.40) {
    return "moderately detailed - include key points with some context";
  } else if (value < 0.60) {
    return "concise and focused - include only essential information";
  } else if (value < 0.80) {
    return "brief and to-the-point - essential information only, no extra details";
  } else {
    return "extremely brief - absolute minimum words, single thought only";
  }
}

function getLengthConstraints(value: number): { maxWords: number; maxSentences: number } {
  if (value < 0.20) {
    return { maxWords: 100, maxSentences: 3 };
  } else if (value < 0.40) {
    return { maxWords: 60, maxSentences: 2 };
  } else if (value < 0.60) {
    return { maxWords: 40, maxSentences: 2 };
  } else if (value < 0.80) {
    return { maxWords: 25, maxSentences: 1 };
  } else {
    return { maxWords: 15, maxSentences: 1 };
  }
}

function calculateMaxTokens(length: number): number {
  const { maxWords } = getLengthConstraints(length);
  // Average word length ~5 chars, so: maxWords * 5 / 4 = tokens
  // Add 50% buffer for safety
  const calculated = Math.ceil((maxWords * 5.0 / 4.0) * 1.5);
  // Ensure reasonable bounds
  return Math.min(Math.max(calculated, 30), 200);
}

