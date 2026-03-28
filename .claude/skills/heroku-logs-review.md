---
name: heroku-logs-review
description: Review Heroku logs for the motzibread app to surface operational issues (R14 memory errors, service failures, job errors, elevated error rates)
autorun: session-start
---

# Heroku Logs Review

Review recent Heroku logs and surface any operational issues. Run this as a background agent at session start so the user is aware of problems before diving into work.

## How to run

Launch a background agent with:

```
heroku logs --app motzibread --num 1500
```

## What to look for

Scan the log output for:

1. **R14/R15 memory errors** — dyno exceeding memory quota. Report which dynos and frequency.
2. **H12/H13/H14 request errors** — request timeouts, connection closed, no web dynos running.
3. **`sample#memory_*` lines** — report current memory usage vs quota for each dyno. Flag if any dyno is above 80% of quota.
4. **Application errors** — Ruby exceptions, job failures, `ActionView::Template::Error`, `ActiveRecord` errors.
5. **Service health** — Sentry rate limiting (429s), New Relic errors (403s), external API failures.
6. **Slow requests** — any request taking over 5 seconds.
7. **Job failures** — SolidQueue jobs that errored or are stuck.
8. **Boot/restart events** — unexpected dyno restarts, deploys, release phase output.

## How to report

If issues are found, report them concisely at the start of your response:

```
Heroku logs check: [summary of issues found]
```

If everything looks healthy, a single line is fine:

```
Heroku logs check: all clear — web.1 at 310MB/512MB, no errors.
```

Do not report on things that are working normally. Only surface problems or notable observations.

## Anomaly report integration

The `CaptureDynoMetricsJob` runs every 30 minutes and stores memory metrics in the `dyno_metrics` table. The `ActivityFeed` includes a "Dyno Memory" section in the anomaly report text. This skill supplements that with real-time, broader log analysis at session start.
