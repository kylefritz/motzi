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

Receives email replies at `motzi-analysis-replies@thepuff.co` via Cloudflare Email Routing. Cloudflare already rejects unauthenticated inbound mail (SPF+DKIM) before the worker runs, so the worker parses the MIME body, extracts the `In-Reply-To` header (shaped like `analysis-<id>@motzibread.herokuapp.com`), and POSTs to the Motzi `/reply_ingress` endpoint with a shared secret. If Motzi rejects, the worker bounces the message back to the sender with an explanation.
