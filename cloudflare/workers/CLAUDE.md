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

Receives email replies at `reply+*@thepuff.co` via Cloudflare Email Routing. Extracts the analysis ID from the To address, verifies SPF/DKIM, parses the email body, and POSTs to the Motzi `/reply_ingress` endpoint with a shared secret. If Motzi rejects (or the email fails verification), the worker bounces the message back to the sender with an explanation.
