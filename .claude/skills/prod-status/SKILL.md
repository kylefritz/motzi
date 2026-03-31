---
name: prod-status
description: Use when starting a conversation, when the user asks about app health, production errors, Heroku status, or when investigating bugs that may be visible in production logs. Covers R14/R15 memory errors, H12/H13/H14 request errors, job failures, dyno restarts, elevated error rates.
---

# Production Status Check

Check recent Heroku logs and surface operational issues so the user knows about problems before diving into work.

## How to run

Launch as a **background agent** so it doesn't block the conversation:

```bash
heroku logs --app motzibread --num 1500
```

Requires `dangerouslyDisableSandbox: true` (hits Heroku API).

## What to scan for

Focus on problems — don't report things that are working normally.

### Memory pressure
- **R14/R15 errors** — dyno exceeded memory quota. Report which dynos and how frequently.
- **`sample#memory_*` lines** — report usage vs quota per dyno. Flag anything above 80% of quota (usually 512MB). Note trends if multiple samples show growth.

### Request errors
- **H12** (request timeout), **H13** (connection closed), **H14** (no web dynos) — users are seeing errors.
- **Slow requests** — anything over 5 seconds.

### Application errors
- **Stacktraces** — Ruby backtraces (`app/...`, `lib/...`, `from /app/...`). Include exception class, message, and first few app-level frames.
- Ruby exceptions (`NoMethodError`, `ArgumentError`, etc.), `ActionView::Template::Error`, `ActiveRecord` errors.
- **500 responses** — `status=500` in router lines means something crashed.
- **Job failures** — SolidQueue errors, `perform` exceptions, retry exhaustion.

### Infrastructure events
- Unexpected dyno restarts, deploys, release phase output.
- SolidQueue jobs that errored or appear stuck.

### Ignore
- Sentry "Discarding" debug lines
- `SolidQueue::Semaphore` cleanup queries
- Rate-limiting messages

## How to report

One line if possible:

```
Prod status: web.1 at 635MB/512MB with R14 errors (6 in last hour), worker.1 healthy at 200MB/512MB
```

```
Prod status: all clear — web.1 at 310MB/512MB, no errors.
```

## Architecture context

Heroku app `motzibread`, auto-deploys from `master`. Heroku Postgres 15 (essential-1). No Redis — SolidQueue (jobs), SolidCable (ActionCable), SolidCache all run on Postgres. `CaptureDynoMetricsJob` runs every 30 min and stores memory snapshots in `dyno_metrics` — this skill supplements that with real-time log analysis.
