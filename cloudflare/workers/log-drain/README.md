# log-drain

Heroku HTTPS log drain → R2, with 30-day retention. Heroku keeps only the last
1,500 log lines; this keeps everything for a month on Cloudflare's free tier.

- `POST https://logs.thepuff.co/<app>/drain`: Heroku's drain. Basic auth; the
  password is `DRAIN_TOKEN`. Logplex frames are converted to `heroku logs`
  lines and buffered in a Durable Object (SQLite), which writes one R2 object
  per minute (or per 1MB) under `<app>/YYYY/MM/DD/HH/`.
- `GET https://logs.thepuff.co/<app>/logs?since=30m&until=<iso>&q=<text>`:
  reads them back, oldest first, including the not-yet-flushed buffer.
  `Authorization: Bearer <READ_TOKEN>`. Long windows are paged: repeat the
  request with `cursor=<X-Next-Cursor>` until the header is absent.
  `bin/prod-logs` and `LogDrain` in the Rails app do this for you.

Apps allowed in the path are listed in `APPS` (`wrangler.toml`).

## Free-tier budget

At `info`, motzi logs roughly 15MB a day (~450MB per 30 days of R2's free
10GB). The minute buffer keeps R2 writes around 1,440 a day (free: 1M a
month); each drain POST is one Worker request, one Durable Object request and
two SQLite row writes (free: 100k a day each).

## Setup

```
bun install
bunx wrangler r2 bucket create thepuff-logs
bunx wrangler r2 bucket lifecycle add thepuff-logs expire-30d --expire-days 30
bunx wrangler deploy                       # custom domain logs.thepuff.co
bunx wrangler secret put DRAIN_TOKEN       # ruby -rsecurerandom -e 'puts SecureRandom.hex(32)'
bunx wrangler secret put READ_TOKEN
heroku drains:add "https://heroku:<DRAIN_TOKEN>@logs.thepuff.co/motzi/drain" --app motzibread
heroku config:set LOG_DRAIN_URL=https://logs.thepuff.co/motzi LOG_DRAIN_READ_TOKEN=<READ_TOKEN> --app motzibread
```

To rotate `DRAIN_TOKEN`, add a drain with the new URL, `wrangler secret put
DRAIN_TOKEN`, then `heroku drains:remove` the old one. For `READ_TOKEN`, put the
secret and update the Heroku config var.

## Tests

`bun test` (logplex parsing, keys, filters) and `bun run typecheck`.
