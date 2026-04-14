# Cloudflare Workers

Deployed via [Wrangler](https://developers.cloudflare.com/workers/wrangler/). Each subdirectory is a separate worker with its own `wrangler.toml`.

## Deploy

```bash
cd cloudflare/workers/<worker-name>
bun install
wrangler deploy
```

## Workers

### reply-ingress

Receives email replies at `motzi-analysis-replies@thepuff.co` via Cloudflare Email Routing. Verifies SPF/DKIM, parses the MIME body, extracts the `In-Reply-To` header (matched against `AnomalyAnalysis#email_message_id`), and POSTs to the Motzi `/reply_ingress` endpoint with a shared secret. If Motzi rejects (or the email fails verification), the worker bounces the message back to the sender with an explanation.
