---
name: prod-status
description: Review Heroku logs for the motzibread app to surface operational issues (memory pressure, service failures, job errors, elevated error rates). Use this at the start of every conversation as instructed in CLAUDE.md, and whenever the user asks about app health, production errors, or Heroku status.
---

# Production Status Check

Check recent production logs and surface operational issues so the user knows about problems before diving into work.

## How to run

Launch as a **background agent** so it doesn't block the conversation. The agent should read the last few hours from the log drain (it requires network access):

```bash
bin/prod-logs --since 6h
```

This needs `dangerouslyDisableSandbox: true` since it hits the network and `heroku config`.

The log drain keeps **30 days** of production logs (Heroku itself keeps only the last 1,500 lines, often just minutes). Use it to look further back or narrow down:

```bash
bin/prod-logs --since 2d -q "status=5"            # 5xx router lines, last 2 days
bin/prod-logs --since 1d -q "Error R15"           # hard memory kills
bin/prod-logs --since 2026-10-19T20:00Z --until 2026-10-19T21:00Z   # one hour
```

`--since` takes `30m`, `6h`, `2d` or an ISO time; `-q` keeps lines containing the text (case-insensitive). Output is the `heroku logs` format. If the drain isn't configured, the script falls back to `heroku logs -n 1500` and says so on stderr. `heroku logs --tail --app motzibread` is still the way to watch live.

Production logs at `info` (no SQL). If a problem needs SQL-level detail, `heroku config:set RAILS_LOG_LEVEL=debug` temporarily, and unset it afterwards.

## What to scan for

Focus on problems — don't report things that are working normally.

### Memory pressure
- **R15 errors** — dyno hard-killed for exceeding 2x quota. This is critical.
- **`sample#memory_*` lines** — report current memory usage vs quota per dyno. Flag anything above 80% of quota (usually 512MB). Note the trend if multiple samples show growth.
- **R14 (soft limit)** — the process goes to swap but keeps running. R14 is a soft warning, not an error. On Heroku's essential tier the process just swaps and continues. Only mention R14 if reporting memory stats anyway; do not elevate status to Warning for R14 alone.

### Request errors
- **H12** (request timeout), **H13** (connection closed), **H14** (no web dynos) — these mean users are seeing errors.
- **Slow requests** — anything over 5 seconds.

### Application errors and stacktraces
- **Stacktraces** — look for lines with Ruby backtraces (`app/...`, `lib/...`, `from /app/...`). When you find one, include the exception class, message, and the first few app-level frames so the user can pinpoint the source.
- Ruby exceptions (`NoMethodError`, `ArgumentError`, `RuntimeError`, etc.), `ActionView::Template::Error`, `ActiveRecord` errors.
- **500 responses** — `status=500` in router lines means something crashed.
- **Job failures** — SolidQueue job errors, `perform` exceptions, retry exhaustion.
- **Ignore noise**: rate-limiting messages are normal — skip them.

### Infrastructure events
- Unexpected dyno restarts, deploys, release phase output.
- SolidQueue jobs that errored or appear stuck.

## How to report

Keep it concise. If issues are found:

```
Prod status: web.1 at 635MB/512MB with H12 timeouts (3 in last hour), worker.1 healthy at 200MB/512MB
```

If everything looks healthy:

```
Prod status: all clear — web.1 at 310MB/512MB, no errors.
```

## Also check

After reviewing logs, also run `gh issue list` to surface any open GitHub issues. Include a one-line summary of any issues that look relevant or urgent in your report.

## Context

The `CaptureDynoMetricsJob` runs every 30 minutes (at :03 and :33), reads the previous 30 minutes from the log drain, and stores memory snapshots in the `dyno_metrics` table. This skill supplements that with broader log analysis — it catches errors and events that the job doesn't track.
