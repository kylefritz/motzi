# Motzi ![](https://github.com/kylefritz/motzi/workflows/ci/badge.svg)

Neighborhood bakery's CSA site

## Development

Requires Postgres and mise (manages Ruby/Bun). Add to `.env`:

```
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
STRIPE_PUBLISHABLE_KEY=...
```

Real data from prod: `bin/seed_local`

Start everything: `bin/dev`

Background jobs use Solid Queue. Run workers with:

```
bin/jobs start
```

Mission Control Jobs UI is mounted at `/jobs` (admin access required).

## JavaScript / TypeScript

Run tests:

```
bun run test
```

Typecheck app code (default gate):

```
bun run typecheck
```

Typecheck tests too (stricter, may expose legacy test typings):

```
bun run typecheck:test
```

Note: React `act(...)` warnings can still appear during `bun run test`; those are runtime test warnings, not TypeScript failures.

### Data

Fixtures: `rails db:fixtures:load fake_data:users fake_data:orders`

### Emails

Visit `/letter_opener` to see emails sent locally.

### Spam users

```
User.find(SqlQuery.new(:spam_user_ids).execute.pluck("id")).each {|u| u.destroy!}
```

## Heroku

Auto-deploys from `master` when CI passes. Full review-app config in `app.json`.

### Addons

| Addon | Plan | Purpose |
|-------|------|---------|
| heroku-postgresql | essential-0 (v17) | Primary database |

ActionCable runs with the `async` adapter in production, so Redis is not required for runtime.

### Recurring jobs

All recurring jobs run via Solid Queue (`config/recurring.yml`):

| Job | Frequency |
|-----|-----------|
| `SendDayOfReminderJob` | Hourly |
| `SendHaventOrderedReminderJob` | Hourly |
| `trim_analytics` | Daily at 4am |

### Email

SendGrid via `SENDGRID_USERNAME` / `SENDGRID_PASSWORD`. On review apps, `ReviewAppMailInterceptor` restricts delivery to admin users only.

### Review apps

`REVIEW_APP=true` set automatically via `app.json`. Use `bin/seed_review_app <app-name>` to copy prod data and config vars.
