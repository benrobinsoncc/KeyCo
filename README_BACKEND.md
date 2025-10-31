# KeyCo Backend API

This backend provides API endpoints for the KeyCo keyboard app, handling AI requests server-side.

## Setup Instructions

### 1. Install Vercel CLI (if not already installed)

```bash
npm install -g vercel
```

### 2. Login to Vercel

```bash
vercel login
```

### 3. Set Environment Variables

Add your OpenAI API key to Vercel:

**Option A: Via Vercel Dashboard**
1. Go to https://vercel.com
2. Create a new project (or select existing)
3. Go to Settings → Environment Variables
4. Add: `OPENAI_API_KEY` = `sk-proj-your-key-here`

**Option B: Via CLI**
```bash
vercel env add OPENAI_API_KEY
# Enter your API key when prompted
```

### 4. Deploy

```bash
vercel
```

Or deploy to production:
```bash
vercel --prod
```

### 5. Update iOS App

After deployment, Vercel will give you a URL like: `https://your-project.vercel.app`

Update `KeyCoKeyboard/BackendConfig.swift`:

```swift
static let baseURL = "https://your-project.vercel.app"
```

## API Endpoints

### POST /api/rewrite

Rewrites text with specified tone and length.

**Request:**
```json
{
  "text": "Hello world",
  "tone": 0.5,
  "length": 0.3
}
```

**Response:**
```json
{
  "text": "Rewritten text here"
}
```

### POST /api/chat

ChatGPT-style query endpoint.

**Request:**
```json
{
  "query": "What is the weather like?"
}
```

**Response:**
```json
{
  "text": "Response from ChatGPT"
}
```

## Local Development

To test locally:

```bash
npm install
vercel dev
```

Then update `BackendConfig.swift` temporarily to:
```swift
static let baseURL = "http://localhost:3000"
```

## File Structure

```
api/
  rewrite.ts      # Tone/length rewrite endpoint
  chat.ts         # ChatGPT query endpoint
package.json      # Dependencies
tsconfig.json     # TypeScript config
vercel.json       # Vercel deployment config
.env.example      # Example environment variables
```

## Notes

- The API key is stored server-side in Vercel environment variables
- Never commit `.env` files to git
- The backend handles all OpenAI API calls, keeping keys secure
- Free tier Vercel should be sufficient for TestFlight and early users

