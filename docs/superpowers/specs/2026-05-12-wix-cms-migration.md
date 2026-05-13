# Wix CMS Migration

**Status:** Draft — awaiting approval before any code is written
**Author:** Kyle, with Claude
**Date:** 2026-05-12

## Problem

motzibread.com is hosted on Wix as a static brochure: 4 pages (home, about/process,
subscribe, contact). The Rails app (`motzibread.herokuapp.com`) hosts the menu, ordering,
and admin. Maintaining two systems means two places to update copy, two bills, and the
brand site is locked into Wix's editor.

We want to fold the marketing pages into the Rails app so there's one codebase to ship,
one set of credentials to manage, and (eventually) one DNS record. We are not trying to
build a general CMS — this is a one-shot scrape + port + retire.

## Goals

1. The four marketing pages render from the Rails app at the existing public paths
   (`/`, `/about`, `/subscribe`, `/contact`), pixel-matched to the current Wix design.
2. The contact form persists submissions to the database AND emails the bakery.
3. All marketing-site assets (logo, hero, farm photos) are self-hosted in S3, no
   dependency on `wixstatic.com`.
4. The bakery can stop paying for / maintaining the Wix subscription.

## Non-Goals

- A general-purpose CMS. Pages live as ERB partials in the repo; edits ship via PR.
- DNS migration. The marketing site goes live on `motzibread.herokuapp.com` first;
  pointing `motzibread.com` at Heroku is a follow-up project.
- Redesign. We're recreating the existing Marisa Grotte design, not improving on it.
- Migrating the Instagram embed. We'll keep the Instagram icon link in the
  header/footer; the live IG feed widget can drop.

## What's on the Wix site today

| Path         | Wix label     | What it is                                                                              |
| ------------ | ------------- | --------------------------------------------------------------------------------------- |
| `/`          | (home)        | Hero taglines, location/hours, retail partners, subscriptions CTA, owner intro, IG feed |
| `/about`     | Our Process   | Sourcing, milling, fermentation, name origin; ~6 farm photos                            |
| `/subscribe` | Subscriptions | Pricing, mechanics, "SOLD OUT" badge, CTA → `/users/sign_up`                            |
| `/contact`   | Contact Us    | Contact form, address (2801 Guilford Ave), phone (443-272-1515), hours                  |

External link surfaces from Wix today:

- "Order" nav link → `motzibread.herokuapp.com` (already us)
- "SUBSCRIBE NOW" CTA → `motzibread.herokuapp.com/users/sign_up` (already us)
- IG link → `instagram.com/motzi.bread`
- Holiday menu → today on Wix this links to `motzibread.square.site`. In the
  migrated site it instead links **in-app** to `menu_path(Menu.current_holiday)`,
  conditionally rendered when `Menu.current_holiday.present?`. Square is being
  retired alongside Wix; holiday pre-orders run through the app from now on.

## Design

### Routes

`root to: "home#show"` already exists in `config/routes.rb` — we keep it and
rewrite the controller (currently a redirect to `/menu`). Add the rest after
existing routes:

```ruby
# root to: "home#show"            # already present; HomeController#show rewritten
get  "/about",     to: "about#show"
get  "/subscribe", to: "subscribe#show"
get  "/contact",   to: "contact#show"
post "/contact",   to: "contact#create"
```

`get ":slug"` catch-all is **not** used — explicit routes only, so we can't accidentally
shadow `/menu`, `/admin`, `/users/sign_up`, etc.

### Controllers

One controller per page, each named after its resource (matches existing
`HomeController` convention — singular):

- `HomeController#show` — **rewrite** the existing controller. Currently
  `redirect_to '/menu'`; becomes a plain render. Already has
  `skip_before_action :authenticate_user!`.
- `AboutController#show` — render only.
- `SubscribeController#show` — render only. (Future home for any
  "are we currently sold out?" logic if it stops being hard-coded copy.)
- `ContactController#show` + `#create` — render the form, then handle the
  submission (validate, create `ContactMessage`, enqueue
  `ContactMailer.notify_bakery(message).deliver_later`, redirect back with a
  flash). Rate-limited via rack-attack (throttle `POST /contact` — 5/hour per IP).

All four `skip_before_action :authenticate_user!` so logged-out visitors get
the marketing site (matches today's Wix behavior).

### Layout

New `app/views/layouts/marketing.html.erb` — separate from the app's
`application.html.erb` so the Wix-style header/footer/typography don't leak into
`/menu` or `/admin` and vice versa. Each of the four marketing controllers
declares `layout "marketing"` (or we extract a tiny `MarketingLayout` concern
if the repetition starts to itch).

The marketing layout includes:

- Top nav: Order (→ `/menu`), Our Process, Subscriptions, Contact Us, IG icon
- **Conditional "Holiday Menu" nav item** when `Menu.current_holiday.present?`,
  linking to `menu_path(Menu.current_holiday)`. Hidden the rest of the year. See
  "Holiday menu surfacing" below.
- For logged-in users (any role): an additional "Account" link that goes to `/menu`,
  and for admins, an "Admin" link to `/admin`
- Footer: address, nav repeat, IG icon, photo/illustration/web design credits, © Motzi LLC

### Holiday menu surfacing

The app already has `Menu.menu_type` (enum: `regular` | `holiday`) and
`Menu.current_holiday` (app/models/menu.rb:19), which reads `Setting.holiday_menu_id`.
Bakers flip a holiday menu live via `holiday_menu.open_for_orders!`
(app/models/menu.rb:66) — that already updates the setting.

The marketing layout calls `Menu.current_holiday` once per render. When non-nil:
show a "Holiday Menu" link (label may end up as the menu's `name` — TBD during
implementation) in the top nav, linking to `menu_path(@holiday)`. When nil: render
nothing extra.

This **replaces** today's Wix→Square holiday flow. No new model, no new setting,
no new admin UI — it's a view-layer addition over an existing primitive.

A small concern: calling `Menu.current_holiday` on every page render adds a query.
Acceptable for marketing pages (low traffic vs. `/menu`). If it ever shows up in
the budget, cache via `Rails.cache.fetch("current_holiday", expires_in: 5.minutes)`
and bust on `Menu#open_for_orders!`.

### Models

```
contact_messages
  id            bigint
  name          string  not null
  email         string  not null
  phone         string  null
  message       text    not null
  ip            string  null   # for abuse review
  user_agent    string  null
  created_at    timestamp
  updated_at    timestamp
```

ActiveAdmin resource for read-only triage (no edit/delete needed; spam can be removed
in batch via console).

### Mailer

`ContactMailer#notify_bakery(message)` — plain-text email to a configured address
(`Rails.application.credentials.contact_inbox` or `ENV["CONTACT_INBOX"]`, defaulting
to the bakery's existing inbox), Reply-To set to the submitter's email so the bakery
can reply directly from their mail client.

### Pages as ERB

Each page is a single ERB file under its controller's view directory:

```
app/views/home/show.html.erb
app/views/about/show.html.erb
app/views/subscribe/show.html.erb
app/views/contact/show.html.erb
```

Recreated layout inline; no partials extracted yet — premature DRY. Copy is
hand-pasted from the Wix scrape (we have the full text already).

### Styling

New `app/assets/stylesheets/marketing.scss`, included only by the marketing layout.
Approach: scoped under `.marketing` body class, hand-written SCSS. Use semantic HTML
(`<header>`, `<section>`, `<article>`) — do **not** copy Wix's nested-div soup.

Fonts: capture the actual font stack from Wix via DevTools (computed styles), match
with Google Fonts equivalents. Likely candidates from the design vibe: a serif display
face for the logo wordmark area, sans-serif body. Confirmed during implementation.

Colors: extract from screenshots / DevTools. Add to `marketing.scss` as variables.

### Assets

One-shot Rake task: `lib/tasks/marketing_assets.rake` → `rake marketing:fetch_assets`:

1. Download every `wixstatic.com` URL referenced in the scraped content (we have a list).
2. Re-upload to `s3://motzi/public/marketing/<original-filename>`.
3. Print a Markdown table mapping original URL → S3 URL, to be pasted into the page ERBs.

Run once. Commit the rake task so the migration is reproducible, but the task is not
intended to run in production.

### Logged-in UX at `/`

Per kyle: marketing home renders for everyone (including logged-in users). Email order
links already use `current_menu_url(uid: ...)` — verified — so they bypass `/` entirely.
Marketing nav shows an "Account" / "Admin" link when `user_signed_in?`.

### Cutover

Phase 1 (this project): ship to `motzibread.herokuapp.com`. Test in prod. Update any
references in the app/emails that still point to `motzibread.com` (probably none —
to confirm during implementation).

Phase 2 (later, separate work): point `motzibread.com` at Heroku via Cloudflare,
add the apex domain in Heroku, get an ACM/Heroku-managed cert, leave Wix subscription
to lapse.

## Risks

- **Pixel-match fidelity vs. effort.** Faithful Wix recreation can absorb unbounded
  time. Mitigation: deploy early, screenshot-diff against the live Wix site, accept
  "looks the same to a stranger" rather than literal pixel equality.
- **Wix images going dark mid-migration.** If the Wix subscription lapses before we
  finish, hot-linked images break. Mitigation: run the asset-fetch rake task in week 1.
- **Contact form spam.** Public email field on a public form. Mitigation: rack-attack
  throttle (5/hr/IP), honeypot field, possibly a simple math captcha if abuse appears.
- **Subscriptions page shows "SOLD OUT" today.** That's a content state, not a
  technical one. We'll port it as-is and leave a TODO for kyle/Maya/Russell to flip
  the copy when they reopen.
- **SEO regression.** Wix has indexed `motzibread.com/about` etc. Once DNS flips
  (Phase 2), Rails serves the same paths — preserves URL structure. If we ever rename
  paths, add 301s.

## Open questions to resolve during implementation

- Which font(s) does the Wix design use? (Capture from DevTools day 1.)
- What email address should the contact form send to? (Ask kyle when wiring the mailer.)
- Should the IG feed embed be replaced with a static "Follow us on IG" CTA, or
  reimplemented via the IG oEmbed/Basic Display API? Default: static CTA, defer the
  embed unless Maya/Russell ask for it.
- What should the Holiday Menu nav link say? Options: literal "Holiday Menu", the
  menu's `name` (e.g. "Rosh Hashanah Pre-orders"), or a setting-controlled label.
  Default: use `Menu.current_holiday.name`.

## Out of scope (suggested follow-ups)

- DNS cutover (`motzibread.com` → Heroku). Separate project.
- Editable CMS (DB-backed pages with admin UI). Only if file-based becomes painful.
- Page-level analytics (Plausible / GA). Probably worth doing alongside cutover.
- Content audit with the owners — phone number, hours, retail partners, owner blurb
  may all be stale on Wix.

## Implementation outline (for the plan, not the spec)

These are the rough work units; a detailed plan with TDD steps comes next via
`writing-plans`.

1. Generate `ContactMessage` model + migration + ActiveAdmin resource
2. Four controllers (`HomeController` rewritten; new `AboutController`,
   `SubscribeController`, `ContactController#show`) + routes + empty ERBs +
   marketing layout shell
3. Marketing SCSS scaffold — typography, colors, header, footer
4. Asset-fetch rake task; run; commit S3 URL map
5. Port `/` (home) — hardest layout; rewrites `HomeController#show` from redirect to render
6. Port `/about` — image-heavy
7. Port `/subscribe` — text + CTA
8. Port `/contact` — form + `ContactController#create` + `ContactMailer` + rack-attack throttle
9. Wire conditional Holiday Menu nav item (uses existing `Menu.current_holiday`)
10. Visual QA: side-by-side screenshots vs Wix at mobile + desktop (reuse the existing
    Playwright/Haiku visual-test pattern — see `test/visual/email-screenshots.spec.ts`)
11. Deploy to Heroku; verify in prod
12. (Phase 2, separately) DNS cutover; retire Square site
