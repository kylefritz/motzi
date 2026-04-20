# motzi-reply-ingress

Cloudflare Email Worker that receives replies to the Motzi Activity Report emails and POSTs them to the Motzi Rails app.

## How it works

1. Motzi's `AnomalyMailer` sends each weekly Activity Report with a deterministic `Message-ID` of `analysis-<id>@motzibread.herokuapp.com` and `Reply-To: motzi-analysis-replies@thepuff.co`.
2. User replies — their email client preserves the original Message-ID in `In-Reply-To`.
3. Cloudflare Email Routing forwards `motzi-analysis-replies@thepuff.co` to this worker. Cloudflare already rejects inbound mail that fails SPF and DKIM at the routing layer, so any message reaching the worker is envelope-authenticated.
4. Worker parses the MIME via `postal-mime` and POSTs the `In-Reply-To` value plus sender/body to `${MOTZI_URL}/reply_ingress` with a Bearer token.
5. Motzi parses the analysis id out of `In-Reply-To`, validates the sender is an admin, and creates an `AnalysisReply`.
6. If anything fails (missing `In-Reply-To`, unknown analysis, non-admin sender, Motzi error), the worker calls `message.setReject(reason)` and Cloudflare bounces the email back to the sender.

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
- Add a custom address: `motzi-analysis-replies@thepuff.co` → action "Send to a Worker" → `motzi-reply-ingress`

## Testing

Send a real reply to a Motzi Activity Report email. Tail logs with `wrangler tail`.
