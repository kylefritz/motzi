---
name: verify
description: Drive Motzi's running dev server end-to-end to verify changes — login shortcuts, order flows, admin, jobs, emails
---

# Verifying Motzi changes at runtime

## Handle

- `bin/dev` runs foreman: Rails web + `bun run build:watch` + Solid Queue worker. If port 3000 is busy it offers an alternate port — check `lsof -iTCP:3001 -sTCP:LISTEN` before starting another server.
- For a throwaway server: `bun run build` (populates `app/assets/builds`), then `DISABLE_SPRING=1 bin/rails server -p <port>`. Worktrees need `bun install` first (no shared node_modules).
- Auth: `GET /dev/login_as_admin` signs in as admin — works for both curl cookie jars (`curl -c jar -L`) and Playwright.
- Admin pages need `-H "Accept: text/html"` with curl or they 302.

## Flows worth driving

- **Member order**: `/menu` (React) → pick a day on an item → Add to cart → Submit/Update Order. Credits counter must move; "We've got your order!" confirms. Edit Order → × an item → Update refunds the credit.
- **Guest buy**: `/menu` logged out shows cash prices; cart total fills the "You pay $" box; tip % updates the charge button. Card charge stays disabled in dev — no `STRIPE_PUBLISHABLE_KEY` in `.env` (expect 2 Stripe IntegrationErrors in console; pre-existing, ignore, along with 1 React hooks-order warning in Layout).
- **Admin**: `/admin/orders` (find the order), `/admin/orders/<id>/edit` → Update round-trip. `/admin/activity_feed`, `/admin/error_events` (+ `.txt` format), `/admin/uptime_checks`, engines `/blazer`, `/jobs`, `/letter_opener`.
- **Email pipeline**: order updates enqueue `ActionMailer::MailDeliveryJob`; confirm delivery in `/letter_opener` (rich view shows the MJML-rendered email).
- **Jobs**: `psql -d motzi -c "select * from solid_queue_processes"` — supervisor/worker/dispatcher/scheduler heartbeats prove the worker is up. `solid_queue_jobs` timestamps are UTC — don't compare against local `now()`.
- **Probes**: `/nonexistent` → custom 404 via ErrorsController; `/health/admin` without token → 404; `POST /reply_ingress` bad secret → 401; `POST /error_events` JSON → 204 + row in `error_events`.

## Gotchas

- Dev DB `motzi` is shared across worktrees and the main checkout — other sessions' migrations show up in your server (PendingMigrationError) and in `db:migrate` schema dumps.
- `AnalyzeAnomaliesJob` fails nightly in dev (Anthropic 400) — pre-existing, not your change.
