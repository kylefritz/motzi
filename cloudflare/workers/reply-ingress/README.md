# motzi-reply-ingress

Cloudflare Email Worker that receives replies to the Motzi Activity Report emails and POSTs them to the Motzi Rails app.

## How it works

1. User replies to the weekly Activity Report email (Reply-To: `reply+analysis-{id}@thepuff.co`).
2. Cloudflare Email Routing forwards `reply+*@thepuff.co` to this worker.
3. Worker verifies SPF and DKIM passed, extracts the analysis ID, parses the email body using `postal-mime`, and POSTs JSON to `${MOTZI_URL}/reply_ingress` with a Bearer token.
4. Motzi validates the sender is an admin and creates an `AnalysisReply`.
5. If anything fails (SPF, DKIM, unknown analysis, non-admin sender, Motzi error), the worker calls `message.setReject(reason)` and Cloudflare bounces the email back to the sender.

## Deploy

```bash
cd cloudflare/workers/reply-ingress
bun install
wrangler login        # once
wrangler secret put REPLY_WEBHOOK_SECRET   # paste the same value as Heroku's REPLY_WEBHOOK_SECRET
wrangler deploy
```

Then in Cloudflare dashboard → thepuff.co → Email → Email Routing:
- Enable Email Routing if not already enabled
- Add a custom address rule: `reply+*@thepuff.co` → send to worker `motzi-reply-ingress`

## Testing

Send a real reply to a Motzi Activity Report email. Tail logs with `wrangler tail`.
