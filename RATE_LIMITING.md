# Rate Limiting Recommendations

## Current Implementation (MVP)

**Simple IP-based rate limiting** using in-memory storage:
- ✅ **Rewrite endpoint**: 100 requests/hour per IP
- ✅ **Chat endpoint**: 50 requests/hour per IP (lower because GPT-4 is more expensive)

### Pros:
- Simple to implement
- Works well for MVP/TestFlight
- Good enough for early users
- No additional costs

### Cons:
- Rate limits are per serverless function instance (not shared)
- Resets when instance restarts
- Not ideal for high-scale production

---

## When to Upgrade (Recommended Limits)

### Current Limits (Good for TestFlight):
- **Rewrite**: 100/hour per IP (~1.6/minute)
- **Chat**: 50/hour per IP (~0.8/minute)

**For keyboard app users:**
- Average user might do 10-20 rewrites per day
- 100/hour is **very generous** for normal use
- Prevents abuse without restricting legitimate users

### If You Need to Tighten (Cost Control):
- **Free tier**: 30-50 rewrites/hour
- **Premium tier**: 100-200 rewrites/hour (if you add subscriptions later)

---

## Future Scaling Options

### Option 2: Vercel KV (Production Scale)

For proper distributed rate limiting, use **Vercel KV**:

```typescript
import { kv } from '@vercel/kv';

// Requires Vercel Pro ($20/month) + KV pricing
// Much better for production scale
```

**Pros:**
- Shared rate limits across all instances
- Persistent storage
- Production-ready

**Cons:**
- Requires Vercel Pro plan
- Additional KV storage costs

### Option 3: Redis (Upstash)

Use **Upstash Redis** (free tier available):

```typescript
import { Redis } from '@upstash/redis';

// Free tier: 10,000 commands/day
// Great for production scale
```

**Pros:**
- Free tier available
- Very fast
- Production-ready
- Scales well

**Cons:**
- Requires external service
- Free tier has limits

---

## Monitoring Recommendations

1. **Track usage in Vercel dashboard**:
   - Monitor function invocations
   - Watch for spikes that indicate abuse

2. **Set up alerts**:
   - Alert if OpenAI costs exceed threshold
   - Alert if rate limit violations spike

3. **Log rate limit hits**:
   - Track which IPs are hitting limits
   - Identify abuse patterns

---

## Adjusting Limits

Edit in `api/rewrite.ts` and `api/chat.ts`:

```typescript
// Current (generous for MVP):
checkRateLimit(clientIP, 100, 60 * 60 * 1000) // 100/hour

// More restrictive (if needed):
checkRateLimit(clientIP, 50, 60 * 60 * 1000)  // 50/hour

// Per-minute limit (stricter):
checkRateLimit(clientIP, 10, 60 * 1000)       // 10/minute
```

---

## Error Handling

When users hit rate limits, they'll see:
```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Please try again in X minutes."
}
```

The iOS app should handle this gracefully - maybe show a user-friendly message instead of the raw error.

---

## Recommendation for Now

**Keep the current simple implementation** - it's perfect for TestFlight and early App Store release. Upgrade to Vercel KV or Upstash Redis when you:
- Have significant user base (1000+ active users)
- Need stricter rate limiting
- See abuse patterns
- Want more sophisticated features (per-user limits, premium tiers, etc.)

