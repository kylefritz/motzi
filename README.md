# Motzi ![](https://github.com/kylefritz/motzi/workflows/ci/badge.svg)

Neighborhood bakery's CSA site

## Development

Requires Postgres, Redis, and mise (manages Ruby/Bun). Add to `.env`:

```
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
STRIPE_PUBLISHABLE_KEY=...
```

Real data from prod: `bin/seed_local`

Start everything: `bin/dev`

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
| heroku-redis | mini | Sidekiq, ActionCable |
| scheduler | standard | Recurring tasks |
| scheduler-monitor | test-free | Monitors scheduler runs |

### Scheduled jobs

| Job | Frequency |
|-----|-----------|
| `rails reminders:havent_ordered reminders:pick_up_bread` | Hourly |
| `rails cleanup:trim_analytics` | Daily |

### Email

SendGrid via `SENDGRID_USERNAME` / `SENDGRID_PASSWORD`. On review apps, `ReviewAppMailInterceptor` restricts delivery to admin users only.

### Review apps

`REVIEW_APP=true` set automatically via `app.json`. Use `bin/seed_review_app <app-name>` to copy prod data and config vars. The seed script verifies scheduler provisioning and lists jobs to configure.
