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

### log-drain

Receives Heroku's HTTPS log drain at `logs.thepuff.co` and stores the lines in the R2 bucket `thepuff-logs` for 30 days; `bin/prod-logs` and `LogDrain` in the Rails app read them back. Secrets: `DRAIN_TOKEN` (write) and `READ_TOKEN` (read). It has tests: `bun test` and `bun run typecheck` in the worker directory (CI does not run them). Setup and token rotation are in its `README.md`.
