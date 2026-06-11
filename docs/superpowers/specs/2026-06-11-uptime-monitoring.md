# Uptime Monitoring — design spec (2026-06-11)

## Goal

Measure site uptime continuously, weighted toward the periods that actually matter,
and detect & track outages without overreacting. The site is used sporadically;
occasional downtime is acceptable — we want *visibility*, not paging.

Extends the one-shot `UptimeProbe` added in PR #337 (which runs once, live, inside
the nightly anomaly report) into a recurring, recorded check.

## Real usage patterns (180 days of Ahoy visits + orders, prod, hours in ET)

- **Wednesday evening is the event of the week.** The weekly menu email lands
  Wed ~6pm: 325 visits and 80 orders in the Wed 6pm hour alone; the surge runs
  5pm–10pm. Wednesday carries ~30% of all orders (366 of 1,219).
- **General traffic** runs ~7am–11pm daily; overnight (11pm–6am) is near-dead.
- **Russell's admin usage** (`users.id=2`, from Ahoy visits joined to admin users
  + `activity_events`): mostly Thu–Sat daytime (Sat 7–8am, Thu/Fri late morning,
  Fri 5–6pm), plus Wednesday evening when the menu goes out.

## Probe targets (verified against prod)

| Target | URL | Expectation | Why |
|--------|-----|-------------|-----|
| `menu` | `{base}/menu.json` | 200 | Anonymous; exercises Rails + Postgres + menu serialization — what a member hitting the menu actually needs. |
| `admin` | `{base}/health/admin?token=…` | 200 | Token-guarded probe-only endpoint (`HealthController`) that runs the admin's real reads server-side: current menu loads, orders readable, error_events readable, ready-job queue not stale. 503 names the failing subcheck; bad/missing token → 404. Falls back to `{base}/admin` (302 → sign-in) when `UPTIME_PROBE_TOKEN` is unset. |

"Up" = HTTP status 200–399. `{base}` comes from `UptimeProbe.url`
(`UPTIME_PROBE_URL` override; defaults to the public site in production; nil in
dev/test → the job no-ops). An authenticated "log in as a real admin" probe was
considered and rejected: it needs stored credentials or a prod auth-bypass
route — a real attack surface — and a brittle sign-in dance in Net::HTTP.

## Check schedule (all times ET)

One Solid Queue recurring job (`UptimeCheckJob`, every 5 minutes). A pure policy
class `UptimeSchedule` decides which targets are due for the current 5-minute
slot (job runs round to the nearest slot, so queue latency can't skip a slot):

- **menu**
  - Wed 5pm–10pm (menu-email surge): every 5 min
  - Daily 7am–11pm: every 15 min
  - Overnight: hourly
- **admin** (Russell's windows only)
  - Wed 4pm–10pm and Thu–Sat 6am–7pm: every 15 min
  - Otherwise: not probed (the menu probe already covers "app is up")

≈ 175 menu + ~70 admin checks/week — trivial load, fine-grained where it counts.

## Data model

`uptime_checks`: `target` (string, NOT NULL), `url`, `status` (int, nullable),
`latency_ms` (int), `error` (string), `up` (boolean NOT NULL), `checked_at`
(datetime NOT NULL). Index on `[target, checked_at]`.

Retention: `TrimAnalyticsJob` deletes rows older than 90 days (same cutoff as
Ahoy data).

## Outage detection (deliberately calm)

A single failed check is data, not an incident (no retries — a blip recorded
next to a success 5 minutes later reads correctly). On the **second consecutive
failure** for a target, report once via
`Rails.error.report(UptimeCheck::OutageError, handled: true, severity: :warning)`
— that lands in `error_events`, so it shows up in `/admin/error_events` and the
weekly feed without paging anyone. No re-report until the target recovers.

**Self-monitoring gap:** if the whole app is down, the worker can't record
"down" either. Missing checks are themselves the signal: the feed compares
actual checks against the expected slot count and reports "N missed slots".

## Surfacing

1. **Activity feed text** (feeds the nightly anomaly prompt): an `== Uptime ==`
   header section per target — `% up`, checks vs expected slots, avg/max latency,
   and a line per failure. Omitted entirely for weeks with no data.
2. **Daily grid**: new "Uptime" column (daily `uptime_summary` events: % up,
   check count, failure count), green/red like the email open-rate cells.
3. **Weekly trends chart**: "Uptime %" dataset on its own 90–100 y-axis (a dip
   from 100 to 99 must be visible; on a 0–100 axis it wouldn't be).
4. **`/admin/uptime_checks`**: read-only ActiveAdmin index with filters, for
   drilling into raw checks.
5. **Prompt** (`anomaly_detection.txt`): explain the Uptime section — failures
   are already counted; missed slots may mean worker downtime or a deploy;
   never ask the operator to "verify the site was accessible".

`UptimeCheckJob` is intentionally **not** added to
`ActivityFeed::RECURRING_JOB_LABELS` — at ~250 runs/week it would drown the
recurring-jobs summary, and uptime has its own section. Failed job executions
still surface through the existing Failed Jobs section.

## PR #337 review feedback addressed

Codex P2: `UptimeProbe.check` built the request from `uri.path` only, silently
dropping the query string of a configured `UPTIME_PROBE_URL`
(e.g. `/health?token=...`). Fix: request the full URI.

## Out of scope

External monitoring (the self-probe gap is acknowledged and partially covered
by missed-slot reporting), paging/alerting, authenticated admin probes,
status-page UI.
