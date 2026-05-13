# Wix CMS Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Wix-hosted motzibread.com marketing site (4 pages: home, about, subscribe, contact) with Rails-served pages in the Motzi app, sharing the existing domain via `motzibread.herokuapp.com`.

**Architecture:** Per-page singular controllers (`HomeController`, `AboutController`, `SubscribeController`, `ContactController`) backed by file-based ERB views in `app/views/<page>/show.html.erb`. Separate `marketing.html.erb` layout and `marketing.scss` so Wix-style typography stays out of `/menu` and `/admin`. Contact form persists `ContactMessage` records and emails the bakery via `ContactMailer`. Holiday menu surfaced through a conditional nav link reading the existing `Menu.current_holiday` primitive. All marketing images downloaded from `wixstatic.com` and re-hosted at `s3://motzi/public/marketing/`.

**Tech Stack:** Rails (existing app), Minitest + fixtures, ActiveAdmin, ActionMailer, Solid Queue (background jobs), rack-attack, Sass via dartsass, Active Storage / S3 (for asset rake task), Playwright + Claude Haiku for visual QA.

**Reference spec:** [`docs/superpowers/specs/2026-05-12-wix-cms-migration.md`](../specs/2026-05-12-wix-cms-migration.md)

---

## File Structure

### New files

```
app/controllers/about_controller.rb
app/controllers/subscribe_controller.rb
app/controllers/contact_controller.rb
app/views/home/show.html.erb
app/views/about/show.html.erb
app/views/subscribe/show.html.erb
app/views/contact/show.html.erb
app/views/layouts/marketing.html.erb
app/views/layouts/_marketing_header.html.erb
app/views/layouts/_marketing_footer.html.erb
app/helpers/marketing_helper.rb
app/assets/stylesheets/marketing.scss
app/models/contact_message.rb
app/mailers/contact_mailer.rb
app/views/contact_mailer/notify_bakery.text.erb
app/admin/contact_messages.rb
db/migrate/<timestamp>_create_contact_messages.rb
lib/tasks/marketing_assets.rake
test/controllers/about_controller_test.rb
test/controllers/subscribe_controller_test.rb
test/controllers/contact_controller_test.rb
test/models/contact_message_test.rb
test/mailers/contact_mailer_test.rb
test/helpers/marketing_helper_test.rb
test/fixtures/contact_messages.yml
test/visual/marketing-screenshots.spec.ts
test/visual/marketing-check-prompt.txt
```

### Modified files

```
app/controllers/home_controller.rb            # rewrite #show: render instead of redirect
test/controllers/home_controller_test.rb      # rewrite test for render path
config/routes.rb                              # add /about, /subscribe, /contact routes
config/initializers/rack_attack.rb            # add throttle for POST /contact
playwright.config.ts                          # nothing changes; verify project picks up new spec
```

---

### Task 1: ContactMessage model + migration

**Files:**
- Create: `db/migrate/<timestamp>_create_contact_messages.rb`
- Create: `app/models/contact_message.rb`
- Create: `test/models/contact_message_test.rb`
- Create: `test/fixtures/contact_messages.yml`

- [ ] **Step 1: Generate the migration**

Run (with `dangerouslyDisableSandbox: true`):
```bash
bin/rails generate migration CreateContactMessages name:string email:string phone:string message:text ip:string user_agent:string
```

Expected: A migration file appears under `db/migrate/<TS>_create_contact_messages.rb`. Open and edit so `name`, `email`, `message` are `null: false`:

```ruby
class CreateContactMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :contact_messages do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.text :message, null: false
      t.string :ip
      t.string :user_agent

      t.timestamps
    end
  end
end
```

- [ ] **Step 2: Run the migration**

```bash
bin/rails db:migrate
```

Expected: `== CreateContactMessages: migrated` appears, no error. `db/schema.rb` updated with the new table.

- [ ] **Step 3: Write the failing model test**

Create `test/models/contact_message_test.rb`:

```ruby
require 'test_helper'

class ContactMessageTest < ActiveSupport::TestCase
  test "valid with name, email, message" do
    msg = ContactMessage.new(name: "Maya", email: "maya@example.com", message: "Hello")
    assert msg.valid?
  end

  test "invalid without name" do
    msg = ContactMessage.new(email: "x@y.com", message: "hi")
    refute msg.valid?
    assert_includes msg.errors[:name], "can't be blank"
  end

  test "invalid without email" do
    msg = ContactMessage.new(name: "X", message: "hi")
    refute msg.valid?
    assert_includes msg.errors[:email], "can't be blank"
  end

  test "invalid with malformed email" do
    msg = ContactMessage.new(name: "X", email: "not-an-email", message: "hi")
    refute msg.valid?
    assert_includes msg.errors[:email], "is invalid"
  end

  test "invalid without message" do
    msg = ContactMessage.new(name: "X", email: "x@y.com")
    refute msg.valid?
    assert_includes msg.errors[:message], "can't be blank"
  end

  test "phone is optional" do
    msg = ContactMessage.new(name: "X", email: "x@y.com", message: "hi")
    assert msg.valid?
  end
end
```

- [ ] **Step 4: Run the test, expect failure**

```bash
bin/rails test test/models/contact_message_test.rb
```

Expected: 5 failures (model file doesn't exist yet, or has no validations).

- [ ] **Step 5: Implement the model**

Create `app/models/contact_message.rb`:

```ruby
class ContactMessage < ApplicationRecord
  validates :name, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
```

- [ ] **Step 6: Run the test, expect pass**

```bash
bin/rails test test/models/contact_message_test.rb
```

Expected: `6 runs, 0 failures, 0 errors, 0 skips`.

- [ ] **Step 7: Add empty fixture file**

Create `test/fixtures/contact_messages.yml`:

```yaml
# Empty by default. Tests that need rows create them inline.
```

- [ ] **Step 8: Commit**

```bash
git add db/migrate/*_create_contact_messages.rb db/schema.rb app/models/contact_message.rb test/models/contact_message_test.rb test/fixtures/contact_messages.yml
git commit -m "Add ContactMessage model for marketing-site contact form"
```

---

### Task 2: ContactMessage ActiveAdmin resource

**Files:**
- Create: `app/admin/contact_messages.rb`

- [ ] **Step 1: Register the resource**

Create `app/admin/contact_messages.rb`:

```ruby
ActiveAdmin.register ContactMessage do
  menu parent: 'Advanced', label: 'Contact Messages', priority: 50

  actions :index, :show, :destroy

  config.filters = false

  index do
    column :created_at do |msg|
      msg.created_at.strftime("%-m/%-d %l:%M%P")
    end
    column :name
    column :email
    column :phone
    column :message do |msg|
      truncate(msg.message, length: 80)
    end
    actions
  end

  show do
    attributes_table do
      row :created_at
      row :name
      row :email
      row :phone
      row :message
      row :ip
      row :user_agent
    end
  end
end
```

- [ ] **Step 2: Verify admin loads**

Start Rails (with `dangerouslyDisableSandbox: true`):
```bash
DISABLE_SPRING=1 bin/rails s -p 3000
```

Visit `http://localhost:3000/admin/contact_messages` (sign in as admin via `/dev/login_as_admin` first if needed). Expect the empty index to render without errors.

Stop the server (Ctrl-C).

- [ ] **Step 3: Commit**

```bash
git add app/admin/contact_messages.rb
git commit -m "Add ActiveAdmin resource for ContactMessage triage"
```

---

### Task 3: Four marketing controllers + routes + layout shell

This task scaffolds all four controllers, the routes, and an empty marketing layout. Pages render but contain only stub content. `HomeController#show` is **not** changed yet — that's Task 13.

**Files:**
- Create: `app/controllers/about_controller.rb`
- Create: `app/controllers/subscribe_controller.rb`
- Create: `app/controllers/contact_controller.rb`
- Create: `app/views/about/show.html.erb`
- Create: `app/views/subscribe/show.html.erb`
- Create: `app/views/contact/show.html.erb`
- Create: `app/views/layouts/marketing.html.erb`
- Create: `app/views/layouts/_marketing_header.html.erb`
- Create: `app/views/layouts/_marketing_footer.html.erb`
- Create: `test/controllers/about_controller_test.rb`
- Create: `test/controllers/subscribe_controller_test.rb`
- Create: `test/controllers/contact_controller_test.rb`
- Modify: `config/routes.rb`

- [ ] **Step 1: Add routes**

In `config/routes.rb`, find the section after `root to: "home#show"` and add:

```ruby
get  "/about",     to: "about#show"
get  "/subscribe", to: "subscribe#show"
get  "/contact",   to: "contact#show"
post "/contact",   to: "contact#create"
```

- [ ] **Step 2: Write failing controller tests**

Create `test/controllers/about_controller_test.rb`:

```ruby
require 'test_helper'

class AboutControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "renders for logged-out visitor" do
    get "/about"
    assert_response :success
    assert_select "body.marketing"
  end

  test "renders for logged-in user" do
    sign_in users(:kyle)
    get "/about"
    assert_response :success
  end
end
```

Create `test/controllers/subscribe_controller_test.rb`:

```ruby
require 'test_helper'

class SubscribeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "renders for logged-out visitor" do
    get "/subscribe"
    assert_response :success
    assert_select "body.marketing"
  end

  test "renders for logged-in user" do
    sign_in users(:kyle)
    get "/subscribe"
    assert_response :success
  end
end
```

Create `test/controllers/contact_controller_test.rb`:

```ruby
require 'test_helper'

class ContactControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "show renders for logged-out visitor" do
    get "/contact"
    assert_response :success
    assert_select "body.marketing"
  end

  test "show renders for logged-in user" do
    sign_in users(:kyle)
    get "/contact"
    assert_response :success
  end
end
```

- [ ] **Step 3: Run tests, expect failure**

```bash
bin/rails test test/controllers/about_controller_test.rb test/controllers/subscribe_controller_test.rb test/controllers/contact_controller_test.rb
```

Expected: All fail with "uninitialized constant AboutController" (etc.).

- [ ] **Step 4: Create the marketing layout**

Create `app/views/layouts/marketing.html.erb`:

```erb
<!DOCTYPE html>
<html lang="en">
  <head>
    <title><%= content_for?(:title) ? "#{yield :title} | Motzi" : "Motzi Bread" %></title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "marketing", media: "all" %>
    <%= yield :head %>
  </head>
  <body class="marketing">
    <%= render "layouts/marketing_header" %>
    <main class="marketing-main">
      <%= yield %>
    </main>
    <%= render "layouts/marketing_footer" %>
  </body>
</html>
```

- [ ] **Step 5: Create stub header partial**

Create `app/views/layouts/_marketing_header.html.erb`:

```erb
<header class="marketing-header">
  <a href="/" class="marketing-logo">Motzi</a>
  <nav class="marketing-nav">
    <a href="/menu">Order</a>
    <a href="/about">Our Process</a>
    <a href="/subscribe">Subscriptions</a>
    <a href="/contact">Contact Us</a>
    <a href="https://www.instagram.com/motzi.bread" target="_blank" rel="noopener">IG</a>
    <% if user_signed_in? %>
      <a href="/menu">Account</a>
      <% if current_user.is_admin? %>
        <a href="/admin">Admin</a>
      <% end %>
    <% end %>
  </nav>
</header>
```

- [ ] **Step 6: Create stub footer partial**

Create `app/views/layouts/_marketing_footer.html.erb`:

```erb
<footer class="marketing-footer">
  <address>
    2801 Guilford Ave<br>
    Baltimore, MD 21218
  </address>
  <nav class="marketing-footer-nav">
    <a href="/menu">Order</a>
    <a href="/about">Our Process</a>
    <a href="/subscribe">Subscriptions</a>
    <a href="/contact">Contact Us</a>
  </nav>
  <p class="marketing-credits">
    Photography: Nathan Mitchell ·
    Illustration: Kate Haberer ·
    Web Design: Marisa Grotte
  </p>
  <p class="marketing-copyright">© <%= Time.current.year %> Motzi LLC</p>
</footer>
```

- [ ] **Step 7: Create the four controllers**

Create `app/controllers/about_controller.rb`:

```ruby
class AboutController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!

  def show
  end
end
```

Create `app/controllers/subscribe_controller.rb`:

```ruby
class SubscribeController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!

  def show
  end
end
```

Create `app/controllers/contact_controller.rb`:

```ruby
class ContactController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!

  def show
    @message = ContactMessage.new
  end
end
```

- [ ] **Step 8: Create stub views**

Create `app/views/about/show.html.erb`:

```erb
<% content_for :title, "Our Process" %>
<h1>Our Process</h1>
<p>Coming soon.</p>
```

Create `app/views/subscribe/show.html.erb`:

```erb
<% content_for :title, "Subscriptions" %>
<h1>Subscriptions</h1>
<p>Coming soon.</p>
```

Create `app/views/contact/show.html.erb`:

```erb
<% content_for :title, "Contact Us" %>
<h1>Contact Us</h1>
<p>Coming soon.</p>
```

- [ ] **Step 9: Create empty marketing.scss so the stylesheet_link_tag resolves**

Create `app/assets/stylesheets/marketing.scss`:

```scss
// Marketing site styles. Filled out in Task 4.
.marketing { }
```

- [ ] **Step 10: Run tests, expect pass**

```bash
bin/rails test test/controllers/about_controller_test.rb test/controllers/subscribe_controller_test.rb test/controllers/contact_controller_test.rb
```

Expected: `6 runs, 0 failures, 0 errors`.

- [ ] **Step 11: Run the full Rails suite to confirm no regressions**

```bash
bin/rails test
```

Expected: All tests pass. (HomeControllerTest still passes — we haven't changed that yet.)

- [ ] **Step 12: Commit**

```bash
git add config/routes.rb app/controllers/about_controller.rb app/controllers/subscribe_controller.rb app/controllers/contact_controller.rb app/views/about/ app/views/subscribe/ app/views/contact/ app/views/layouts/marketing.html.erb app/views/layouts/_marketing_header.html.erb app/views/layouts/_marketing_footer.html.erb app/assets/stylesheets/marketing.scss test/controllers/about_controller_test.rb test/controllers/subscribe_controller_test.rb test/controllers/contact_controller_test.rb
git commit -m "Scaffold marketing controllers, layout, and routes for /about /subscribe /contact"
```

---

### Task 4: Marketing SCSS scaffold

Fill in real header, footer, and typography styles. Pixel-matching the Wix design — capture font and color values from the live Wix site via Chrome DevTools and substitute below where placeholders appear.

**Files:**
- Modify: `app/assets/stylesheets/marketing.scss`

- [ ] **Step 1: Capture Wix design values from DevTools**

Open `https://www.motzibread.com/` in Chrome with DevTools open. For each major element (logo wordmark, nav links, headings, body text), inspect the **Computed** tab and note:
- `font-family`
- `font-size`
- `color`
- Background colors of header/footer
- Brand accent color (red used for headings/CTAs — matches the existing app's `#D5482C` from `app/views/menu_mailer/weekly_menu_email.mjml:27`)

Write the captured values into a temporary `notes/wix-design.md` file (do NOT commit). They'll feed into Step 2.

- [ ] **Step 2: Write the SCSS scaffold**

Replace `app/assets/stylesheets/marketing.scss` contents with the following. **Substitute** the placeholder font names and any colors that DevTools showed differently:

```scss
// Marketing site styles. Scoped under .marketing so they don't leak into
// /menu or /admin (which use application.scss + ActiveAdmin styles).

$marketing-bg: #FFECD6;        // confirm via DevTools — matches existing brand cream
$marketing-text: #2E2927;
$marketing-accent: #D5482C;    // matches the bakery's brand red
$marketing-muted: #6B5E4F;
$marketing-display-font: "Playfair Display", Georgia, serif;  // confirm
$marketing-body-font: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;  // confirm

body.marketing {
  margin: 0;
  background: $marketing-bg;
  color: $marketing-text;
  font-family: $marketing-body-font;
  font-size: 17px;
  line-height: 1.6;

  h1, h2, h3 {
    font-family: $marketing-display-font;
    font-weight: 600;
    letter-spacing: -0.01em;
  }

  h1 { font-size: clamp(2rem, 4vw, 3rem); margin: 0 0 1rem; }
  h2 { font-size: clamp(1.5rem, 3vw, 2rem); margin: 2rem 0 0.75rem; }

  a { color: $marketing-accent; }
}

.marketing-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid rgba($marketing-text, 0.08);

  .marketing-logo {
    font-family: $marketing-display-font;
    font-size: 1.5rem;
    text-decoration: none;
    color: $marketing-text;
  }

  .marketing-nav {
    display: flex;
    gap: 1.25rem;

    a {
      color: $marketing-text;
      text-decoration: none;
      font-size: 0.95rem;

      &:hover { color: $marketing-accent; }
    }
  }
}

.marketing-main {
  max-width: 960px;
  margin: 0 auto;
  padding: 3rem 2rem;
}

.marketing-footer {
  padding: 3rem 2rem 2rem;
  background: rgba($marketing-text, 0.03);
  text-align: center;

  address {
    font-style: normal;
    margin-bottom: 1rem;
  }

  .marketing-footer-nav {
    display: flex;
    gap: 1.25rem;
    justify-content: center;
    margin-bottom: 1.5rem;

    a { color: $marketing-text; text-decoration: none; }
  }

  .marketing-credits, .marketing-copyright {
    font-size: 0.85rem;
    color: $marketing-muted;
    margin: 0.5rem 0;
  }
}

@media (max-width: 640px) {
  .marketing-header {
    flex-direction: column;
    gap: 1rem;
    padding: 1rem;
  }
  .marketing-nav { flex-wrap: wrap; justify-content: center; }
  .marketing-main { padding: 2rem 1rem; }
}
```

- [ ] **Step 3: If using Google Fonts, add the link tag to the layout**

Edit `app/views/layouts/marketing.html.erb` and add into `<head>` before the stylesheet tag:

```erb
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Playfair+Display:wght@600;700&display=swap" rel="stylesheet">
```

(Adjust to whatever fonts you confirmed in Step 1.)

- [ ] **Step 4: Verify visually**

```bash
DISABLE_SPRING=1 bin/rails s -p 3000
```

Visit `http://localhost:3000/about`. Expect: cream background, serif display font on the H1, sans body font on the paragraph, header with logo + nav, footer with address and credits. Compare side-by-side with `https://www.motzibread.com/about` — the *vibe* (color, typography, spacing) should match. Pixel-perfect comes through iteration.

Stop the server.

- [ ] **Step 5: Run the test suite to confirm nothing broke**

```bash
bin/rails test
```

Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add app/assets/stylesheets/marketing.scss app/views/layouts/marketing.html.erb
git commit -m "Add marketing-site SCSS scaffold (typography, header, footer)"
```

---

### Task 5: Asset-fetch rake task

One-shot task to download Wix-hosted images and re-upload to S3. Run **once locally** to populate `s3://motzi/public/marketing/`, then commit the rake task and the resulting URL map.

**Files:**
- Create: `lib/tasks/marketing_assets.rake`
- Create: `docs/superpowers/specs/marketing-assets-map.md` (URL map artifact)

- [ ] **Step 1: Write the rake task**

Create `lib/tasks/marketing_assets.rake`:

```ruby
require "open-uri"
require "aws-sdk-s3"

namespace :marketing do
  # One-shot: download images from wixstatic.com and re-upload to s3://motzi/public/marketing/
  # Run locally: bundle exec rake marketing:fetch_assets
  desc "Download marketing images from Wix and upload to S3"
  task fetch_assets: :environment do
    sources = [
      # Logo & generic
      "https://static.wixstatic.com/media/0e6926_461ca570e24f4af18aff571baa07cea2~mv2.png",
      "https://static.wixstatic.com/media/0e6926_2bd61b90080c4d7f895840a4ab150e5e~mv2.jpg",
      "https://static.wixstatic.com/media/40898a93cfff4578b1779073137eb1b4.png",
      # /about page photos (filenames captured during the spec scrape)
      # Add more URLs as they are discovered while porting each page.
    ]

    s3 = Aws::S3::Resource.new(region: "us-east-1")
    bucket = s3.bucket("motzi")

    map = []
    sources.each do |url|
      filename = File.basename(URI(url).path).gsub(/[^A-Za-z0-9._-]/, "_")
      key = "public/marketing/#{filename}"
      puts "Downloading #{url}..."
      data = URI.open(url).read
      bucket.object(key).put(body: data, acl: "public-read", content_type: Marcel::MimeType.for(StringIO.new(data)))
      s3_url = "https://motzi.s3.us-east-1.amazonaws.com/#{key}"
      map << [url, s3_url]
      puts "  -> #{s3_url}"
    end

    puts "\n## Asset map\n\n| Original | S3 |\n|---|---|"
    map.each { |orig, s3| puts "| `#{orig}` | `#{s3}` |" }
  end
end
```

- [ ] **Step 2: Run the task**

```bash
bundle exec rake marketing:fetch_assets
```

Expected: Each URL downloads and uploads, and a final markdown table prints to stdout.

If it fails with credentials error, confirm `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` are set in `.env` and that the IAM user can write to `s3://motzi/public/marketing/`.

- [ ] **Step 3: Capture the URL map**

Copy the printed markdown table into a new file `docs/superpowers/specs/marketing-assets-map.md`:

```markdown
# Marketing assets — original → S3 map

Generated from `rake marketing:fetch_assets` on <DATE>. Use the right column when
referencing images in `app/views/{home,about,subscribe,contact}/show.html.erb`.

| Original | S3 |
|---|---|
| `https://static.wixstatic.com/media/0e6926_461ca570e24f4af18aff571baa07cea2~mv2.png` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/0e6926_461ca570e24f4af18aff571baa07cea2_mv2.png` |
| ...rest of table... |
```

- [ ] **Step 4: Spot-check one URL in a browser**

Open one of the S3 URLs from the map in a browser. Expect the image to display directly (public-read).

- [ ] **Step 5: Commit**

```bash
git add lib/tasks/marketing_assets.rake docs/superpowers/specs/marketing-assets-map.md
git commit -m "Add one-shot rake task to mirror Wix marketing assets to S3"
```

---

### Task 6: Port `/about`

Recreate the "Our Process" page with the scraped content and the S3-hosted images.

**Files:**
- Modify: `app/views/about/show.html.erb`
- Modify: `test/controllers/about_controller_test.rb`

- [ ] **Step 1: Add an extra failing assertion to the about controller test**

Edit `test/controllers/about_controller_test.rb` and add:

```ruby
test "renders the Our Process heading and key sections" do
  get "/about"
  assert_select "h1", text: /Our Process/i
  assert_select "h2", text: /Local Sourcing/i
  assert_select "h2", text: /Fresh Milling/i
  assert_select "h2", text: /Long Fermentation/i
end
```

- [ ] **Step 2: Run the test, expect failure**

```bash
bin/rails test test/controllers/about_controller_test.rb
```

Expected: The new test fails (stub view only has "Coming soon").

- [ ] **Step 3: Replace the about view with real content**

Replace `app/views/about/show.html.erb` with (substituting the asset URLs from `marketing-assets-map.md`):

```erb
<% content_for :title, "Our Process" %>

<article class="page-about">
  <header class="page-hero">
    <h1>Our Process</h1>
    <p class="lede">Every part of our process contributes to the flavor and nutrition of the bread.</p>
  </header>

  <section>
    <h2>Local Sourcing</h2>
    <p>We partner with regional farmers practicing regenerative agriculture. Key suppliers include:</p>
    <ul>
      <li>Migrash Farm — Red Fife wheat, Bolles wheat, Abruzzi rye, Tuxpeño corn, spelt</li>
      <li>Pecan Meadow Farms — Pennoll wheat</li>
      <li>Buffalo Valley Pastures — Einkorn wheat</li>
      <li>Next Step Produce — buckwheat, oats, sunflower seeds, sesame seeds</li>
    </ul>
    <figure>
      <img src="<%# REPLACE WITH S3 URL FROM ASSET MAP %>" alt="Heinz Thomet of Next Step Produce">
      <figcaption>Heinz Thomet of Next Step Produce — Photo by Raphaelle Lajoie</figcaption>
    </figure>
  </section>

  <section>
    <h2>Fresh Milling &amp; Whole Grain</h2>
    <p>The flavor of flour is at its peak the moment it's milled. We use a Zentrofan stone mill from Germany to mill whole grain in-house weekly.</p>
  </section>

  <section>
    <h2>Long Fermentation</h2>
    <p>Sourdough fermentation, run long, makes the bread more digestible and gives it a complex flavor and crisp crust.</p>
  </section>

  <section>
    <h2>The Name</h2>
    <p>"Motzi" references the Hebrew blessing over bread. We treat baking as a sacred act, and offer pay-what-you-can pricing to make this bread accessible.</p>
  </section>
</article>
```

Ensure each `<img>`'s `src` is replaced with the corresponding S3 URL from `docs/superpowers/specs/marketing-assets-map.md`.

- [ ] **Step 4: Run tests, expect pass**

```bash
bin/rails test test/controllers/about_controller_test.rb
```

Expected: `3 runs, 0 failures`.

- [ ] **Step 5: Eyeball the page**

```bash
DISABLE_SPRING=1 bin/rails s -p 3000
```

Visit `http://localhost:3000/about`. Confirm: H1, four H2 sections, image renders from S3, no broken links.

Stop the server.

- [ ] **Step 6: Commit**

```bash
git add app/views/about/show.html.erb test/controllers/about_controller_test.rb
git commit -m "Port /about (Our Process) page from Wix"
```

---

### Task 7: Port `/subscribe`

**Files:**
- Modify: `app/views/subscribe/show.html.erb`
- Modify: `test/controllers/subscribe_controller_test.rb`

- [ ] **Step 1: Add failing content assertion**

Edit `test/controllers/subscribe_controller_test.rb` and add:

```ruby
test "renders subscription details and CTA to sign up" do
  get "/subscribe"
  assert_select "h1", text: /Subscriptions/i
  assert_select "a[href=?]", "/users/sign_up", text: /SUBSCRIBE NOW/i
end
```

- [ ] **Step 2: Run, expect failure**

```bash
bin/rails test test/controllers/subscribe_controller_test.rb
```

- [ ] **Step 3: Replace the subscribe view**

Replace `app/views/subscribe/show.html.erb`:

```erb
<% content_for :title, "Subscriptions" %>

<article class="page-subscribe">
  <header class="page-hero">
    <h1>Subscriptions</h1>
    <p class="lede">Want our bread on a regular basis? Consider a subscription, which provides a discount on each loaf and supports our business.</p>
  </header>

  <p class="badge-soldout">Currently Sold Out</p>

  <section>
    <h2>Why Subscribe</h2>
    <ul>
      <li>Per-loaf discount</li>
      <li>Occasional special loaves</li>
      <li>Guaranteed availability when sold out for general sale</li>
      <li>You help our small business plan ahead</li>
    </ul>
  </section>

  <section>
    <h2>How It Works</h2>
    <ul>
      <li>Credits are purchased upfront and redeemed via the online preorder platform</li>
      <li>Weekly menu emails; preorders due by 9pm the day before pickup</li>
      <li>Credits cannot be used in-store</li>
      <li>1 credit = 1 loaf or several pastries</li>
      <li>Storefront pickup only — no farmers market pickup for preorders</li>
      <li>Credits never expire</li>
      <li>Challah and holiday items excluded from subscriber purchases</li>
    </ul>
  </section>

  <section>
    <h2>Pricing</h2>
    <ul>
      <li><strong>$182 for 26 credits</strong> ($7.00/loaf) — weekly for 6 months</li>
      <li><strong>$98 for 13 credits</strong> ($7.50/loaf) — bi-weekly for 6 months</li>
    </ul>
  </section>

  <p class="cta-row">
    <a href="/users/sign_up" class="cta-primary">SUBSCRIBE NOW</a>
  </p>
</article>
```

- [ ] **Step 4: Run tests, expect pass**

```bash
bin/rails test test/controllers/subscribe_controller_test.rb
```

- [ ] **Step 5: Commit**

```bash
git add app/views/subscribe/show.html.erb test/controllers/subscribe_controller_test.rb
git commit -m "Port /subscribe page from Wix"
```

---

### Task 8: Port `/contact` (static info; form added in Task 9)

**Files:**
- Modify: `app/views/contact/show.html.erb`
- Modify: `test/controllers/contact_controller_test.rb`

- [ ] **Step 1: Add failing assertion for static contact info**

Edit `test/controllers/contact_controller_test.rb` and add:

```ruby
test "renders bakery address, phone, and hours" do
  get "/contact"
  assert_select "h1", text: /Contact Us/i
  assert_select "address", text: /2801 Guilford Ave/
  assert_match /443-272-1515/, @response.body
  assert_match /Tues.*Sat/i, @response.body
end
```

- [ ] **Step 2: Run, expect failure**

```bash
bin/rails test test/controllers/contact_controller_test.rb
```

- [ ] **Step 3: Replace the contact view (no form yet)**

Replace `app/views/contact/show.html.erb`:

```erb
<% content_for :title, "Contact Us" %>

<article class="page-contact">
  <header class="page-hero">
    <h1>Contact Us</h1>
    <p class="lede">We'd love to hear from you!</p>
  </header>

  <section class="contact-details">
    <address>
      2801 Guilford Ave<br>
      Baltimore, MD 21218
    </address>
    <p><strong>Phone:</strong> 443-272-1515 (Tues – Sat)</p>
  </section>

  <%# Form added in Task 9 %>
</article>
```

- [ ] **Step 4: Run tests, expect pass**

```bash
bin/rails test test/controllers/contact_controller_test.rb
```

- [ ] **Step 5: Commit**

```bash
git add app/views/contact/show.html.erb test/controllers/contact_controller_test.rb
git commit -m "Port /contact static info (address, phone, hours) from Wix"
```

---

### Task 9: Contact form HTML + ContactController#create + tests (DB only, no email yet)

Add the form, the create action, and tests for both happy and sad paths. **No mailer yet** — that comes in Task 10. This task is shippable on its own: form submissions persist to the DB and show in `/admin`.

**Files:**
- Modify: `app/views/contact/show.html.erb`
- Modify: `app/controllers/contact_controller.rb`
- Modify: `test/controllers/contact_controller_test.rb`

- [ ] **Step 1: Write failing tests for the form flow**

Add to `test/controllers/contact_controller_test.rb`:

```ruby
test "show renders the form" do
  get "/contact"
  assert_select "form[action=?][method=?]", "/contact", "post"
  assert_select "input[name='contact_message[name]']"
  assert_select "input[name='contact_message[email]']"
  assert_select "input[name='contact_message[phone]']"
  assert_select "textarea[name='contact_message[message]']"
end

test "create with valid params persists a ContactMessage and redirects" do
  assert_difference -> { ContactMessage.count }, 1 do
    post "/contact", params: { contact_message: {
      name: "Maya", email: "maya@example.com", phone: "555-1212", message: "Hello!"
    } }
  end
  assert_redirected_to "/contact"
  follow_redirect!
  assert_match /thanks/i, @response.body
end

test "create captures ip and user_agent" do
  post "/contact", params: { contact_message: {
    name: "X", email: "x@y.com", message: "hi"
  } }, headers: { "User-Agent" => "TestBot/1.0" }
  msg = ContactMessage.order(:created_at).last
  assert_equal "TestBot/1.0", msg.user_agent
  assert_not_nil msg.ip
end

test "create with invalid params re-renders show with 422" do
  assert_no_difference -> { ContactMessage.count } do
    post "/contact", params: { contact_message: { name: "", email: "", message: "" } }
  end
  assert_response :unprocessable_entity
  assert_select "form[action=?]", "/contact"
end

test "honeypot field silently swallows submission" do
  assert_no_difference -> { ContactMessage.count } do
    post "/contact", params: { contact_message: {
      name: "Spammer", email: "spam@bad.com", message: "buy stuff", website: "http://bad.example"
    } }
  end
  assert_redirected_to "/contact"  # bot thinks it succeeded
end
```

- [ ] **Step 2: Run, expect failure**

```bash
bin/rails test test/controllers/contact_controller_test.rb
```

Expected: Five new failures.

- [ ] **Step 3: Update the contact view to include the form (and honeypot)**

Replace `app/views/contact/show.html.erb`:

```erb
<% content_for :title, "Contact Us" %>

<article class="page-contact">
  <header class="page-hero">
    <h1>Contact Us</h1>
    <p class="lede">We'd love to hear from you!</p>
  </header>

  <section class="contact-details">
    <address>
      2801 Guilford Ave<br>
      Baltimore, MD 21218
    </address>
    <p><strong>Phone:</strong> 443-272-1515 (Tues – Sat)</p>
  </section>

  <%= form_with model: @message, url: "/contact", local: true, html: { class: "contact-form" } do |f| %>
    <% if @message.errors.any? %>
      <div class="form-errors">
        <p>Please fix the following:</p>
        <ul>
          <% @message.errors.full_messages.each do |msg| %>
            <li><%= msg %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div class="field">
      <%= f.label :name %>
      <%= f.text_field :name, required: true, autocomplete: "name" %>
    </div>

    <div class="field">
      <%= f.label :email %>
      <%= f.email_field :email, required: true, autocomplete: "email" %>
    </div>

    <div class="field">
      <%= f.label :phone, "Phone (optional)" %>
      <%= f.telephone_field :phone, autocomplete: "tel" %>
    </div>

    <div class="field">
      <%= f.label :message %>
      <%= f.text_area :message, rows: 6, required: true %>
    </div>

    <%# Honeypot — humans don't fill this in. CSS hides it visually. %>
    <div class="hp-field" aria-hidden="true" style="position:absolute;left:-9999px">
      <label for="contact_message_website">Website (leave blank)</label>
      <input type="text" name="contact_message[website]" id="contact_message_website" tabindex="-1" autocomplete="off">
    </div>

    <%= f.submit "Send" %>
  <% end %>
</article>
```

- [ ] **Step 4: Implement `ContactController#create`**

Replace `app/controllers/contact_controller.rb`:

```ruby
class ContactController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!

  def show
    @message = ContactMessage.new
  end

  def create
    # Honeypot: silently 200 a bot without persisting.
    if params.dig(:contact_message, :website).present?
      redirect_to "/contact", notice: "Thanks! We'll be in touch."
      return
    end

    @message = ContactMessage.new(contact_message_params)
    @message.ip = request.remote_ip
    @message.user_agent = request.user_agent

    if @message.save
      redirect_to "/contact", notice: "Thanks! We'll be in touch."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(:name, :email, :phone, :message)
  end
end
```

- [ ] **Step 5: Run tests, expect pass**

```bash
bin/rails test test/controllers/contact_controller_test.rb
```

Expected: All tests pass.

- [ ] **Step 6: Manual smoke test**

```bash
DISABLE_SPRING=1 bin/rails s -p 3000
```

Visit `/contact`, fill the form, submit. Expect: redirect back with the "Thanks!" flash. Visit `/admin/contact_messages` — your submission should appear.

Stop the server.

- [ ] **Step 7: Commit**

```bash
git add app/views/contact/show.html.erb app/controllers/contact_controller.rb test/controllers/contact_controller_test.rb
git commit -m "Add contact form: persist ContactMessage with honeypot, render errors"
```

---

### Task 10: ContactMailer + wire to ContactController

**Files:**
- Create: `app/mailers/contact_mailer.rb`
- Create: `app/views/contact_mailer/notify_bakery.text.erb`
- Create: `test/mailers/contact_mailer_test.rb`
- Modify: `app/controllers/contact_controller.rb`
- Modify: `test/controllers/contact_controller_test.rb`

- [ ] **Step 1: Write the failing mailer test**

Create `test/mailers/contact_mailer_test.rb`:

```ruby
require 'test_helper'

class ContactMailerTest < ActionMailer::TestCase
  test "notify_bakery sends to the configured inbox with submitter as Reply-To" do
    msg = ContactMessage.create!(
      name: "Maya",
      email: "maya@example.com",
      phone: "555-1212",
      message: "Quick question about subscriptions."
    )

    email = ContactMailer.notify_bakery(msg)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ENV.fetch("CONTACT_INBOX", "info@motzibread.com")], email.to
    assert_equal ["maya@example.com"], email.reply_to
    assert_match /Maya/, email.subject
    assert_includes email.body.to_s, "Quick question about subscriptions"
    assert_includes email.body.to_s, "555-1212"
    assert_includes email.body.to_s, "maya@example.com"
  end

  test "phone is omitted from body when blank" do
    msg = ContactMessage.create!(name: "X", email: "x@y.com", message: "hi")
    email = ContactMailer.notify_bakery(msg)
    refute_match /Phone:/, email.body.to_s
  end
end
```

- [ ] **Step 2: Run, expect failure**

```bash
bin/rails test test/mailers/contact_mailer_test.rb
```

- [ ] **Step 3: Implement the mailer**

Create `app/mailers/contact_mailer.rb`:

```ruby
class ContactMailer < ApplicationMailer
  def notify_bakery(contact_message)
    @msg = contact_message
    mail(
      to: ENV.fetch("CONTACT_INBOX", "info@motzibread.com"),
      reply_to: contact_message.email,
      subject: "New contact form message from #{contact_message.name}"
    )
  end
end
```

Create `app/views/contact_mailer/notify_bakery.text.erb`:

```erb
New message from the motzibread.com contact form:

From: <%= @msg.name %> <<%= @msg.email %>>
<% if @msg.phone.present? %>Phone: <%= @msg.phone %>
<% end %>
Sent: <%= @msg.created_at.strftime("%a %b %-d %Y, %l:%M %P") %>

Message:
---
<%= @msg.message %>
---

View in admin: <%= ENV.fetch("APP_HOST", "https://motzibread.herokuapp.com") %>/admin/contact_messages/<%= @msg.id %>
```

- [ ] **Step 4: Run mailer test, expect pass**

```bash
bin/rails test test/mailers/contact_mailer_test.rb
```

- [ ] **Step 5: Wire the mailer into the controller**

Edit `app/controllers/contact_controller.rb` and modify the `create` action's success branch:

Replace:
```ruby
    if @message.save
      redirect_to "/contact", notice: "Thanks! We'll be in touch."
    else
```

With:
```ruby
    if @message.save
      ContactMailer.notify_bakery(@message).deliver_later
      redirect_to "/contact", notice: "Thanks! We'll be in touch."
    else
```

- [ ] **Step 6: Add a controller test for mail delivery**

Add to `test/controllers/contact_controller_test.rb`:

```ruby
include ActiveJob::TestHelper

test "create enqueues the bakery notification email" do
  assert_enqueued_emails 1 do
    post "/contact", params: { contact_message: {
      name: "Maya", email: "maya@example.com", message: "Hello!"
    } }
  end
end

test "honeypot does NOT enqueue email" do
  assert_enqueued_emails 0 do
    post "/contact", params: { contact_message: {
      name: "Bot", email: "bot@bad.com", message: "spam", website: "http://bad"
    } }
  end
end
```

- [ ] **Step 7: Run controller tests**

```bash
bin/rails test test/controllers/contact_controller_test.rb test/mailers/contact_mailer_test.rb
```

Expected: All pass.

- [ ] **Step 8: Commit**

```bash
git add app/mailers/contact_mailer.rb app/views/contact_mailer/ test/mailers/contact_mailer_test.rb app/controllers/contact_controller.rb test/controllers/contact_controller_test.rb
git commit -m "Email contact form submissions to the bakery via ContactMailer"
```

---

### Task 11: rack-attack throttle for POST /contact

**Files:**
- Modify: `config/initializers/rack_attack.rb`
- Modify: `test/integration/rack_attack_test.rb`

- [ ] **Step 1: Write the failing throttle test**

Append to `test/integration/rack_attack_test.rb` (inside the existing class, before `end`):

```ruby
test "throttles excessive POST /contact submissions per IP" do
  Rack::Attack.cache.store.clear  # reset throttle counters

  valid_params = { contact_message: { name: "X", email: "x@y.com", message: "hi" } }

  # First 5 requests succeed (or 422 — either way, not throttled).
  5.times do
    post "/contact", params: valid_params, env: { "REMOTE_ADDR" => "1.2.3.4" }
    refute_equal 429, response.status, "should not be throttled within limit"
  end

  # 6th request hits the throttle.
  post "/contact", params: valid_params, env: { "REMOTE_ADDR" => "1.2.3.4" }
  assert_response :too_many_requests
end

test "GET /contact is not throttled" do
  Rack::Attack.cache.store.clear
  10.times { get "/contact", env: { "REMOTE_ADDR" => "5.6.7.8" } }
  assert_response :success
end
```

- [ ] **Step 2: Run, expect failure**

```bash
bin/rails test test/integration/rack_attack_test.rb
```

- [ ] **Step 3: Add the throttle**

Edit `config/initializers/rack_attack.rb` and add **before** the final
`Rack::Attack.blocklisted_responder = ...` line:

```ruby
  # Limit contact form submissions to 5 per hour per IP. The form is public, so
  # this is the main spam mitigation alongside the view-layer honeypot field.
  throttle("contact form per ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/contact" && req.post?
  end
```

(The `throttle` block goes inside the `class Rack::Attack` definition, alongside the existing `blocklist`.)

Also add a throttled responder so the test's `:too_many_requests` assertion fires:

```ruby
Rack::Attack.throttled_responder = ->(_req) { [429, { "Content-Type" => "text/plain" }, ["Too Many Requests"]] }
```

- [ ] **Step 4: Run tests, expect pass**

```bash
bin/rails test test/integration/rack_attack_test.rb
```

- [ ] **Step 5: Commit**

```bash
git add config/initializers/rack_attack.rb test/integration/rack_attack_test.rb
git commit -m "Throttle POST /contact at 5 per hour per IP via rack-attack"
```

---

### Task 12: Holiday menu nav helper + integration

**Files:**
- Create: `app/helpers/marketing_helper.rb`
- Create: `test/helpers/marketing_helper_test.rb`
- Modify: `app/views/layouts/_marketing_header.html.erb`

- [ ] **Step 1: Write the failing helper test**

Create `test/helpers/marketing_helper_test.rb`:

```ruby
require 'test_helper'

class MarketingHelperTest < ActionView::TestCase
  include MarketingHelper

  test "holiday_menu_link returns nil when no current holiday" do
    Setting.holiday_menu_id = nil
    assert_nil holiday_menu_link
  end

  test "holiday_menu_link returns a link to the menu when one is current" do
    holiday = Menu.create!(name: "Rosh Hashanah Pre-orders", week_id: "26w36", menu_type: "holiday")
    Setting.holiday_menu_id = holiday.id

    link = holiday_menu_link
    assert_not_nil link
    assert_match holiday.name, link
    assert_match menu_path(holiday), link
  ensure
    Setting.holiday_menu_id = nil
    holiday&.destroy
  end
end
```

- [ ] **Step 2: Run, expect failure**

```bash
bin/rails test test/helpers/marketing_helper_test.rb
```

- [ ] **Step 3: Implement the helper**

Create `app/helpers/marketing_helper.rb`:

```ruby
module MarketingHelper
  # Returns an HTML <a> linking to the current holiday menu, or nil when none is active.
  # Reads the existing Menu.current_holiday primitive (app/models/menu.rb).
  def holiday_menu_link
    holiday = Menu.current_holiday
    return nil if holiday.nil?

    link_to(holiday.name, menu_path(holiday), class: "marketing-nav-holiday")
  end
end
```

- [ ] **Step 4: Run helper test, expect pass**

```bash
bin/rails test test/helpers/marketing_helper_test.rb
```

- [ ] **Step 5: Use the helper in the marketing header**

Edit `app/views/layouts/_marketing_header.html.erb` and insert this line into the `<nav>`, just after the `<a href="/menu">Order</a>` line:

```erb
<%= holiday_menu_link %>
```

- [ ] **Step 6: Add a controller-level test that the layout renders the link conditionally**

Append to `test/controllers/about_controller_test.rb` (any marketing-page test would do — about is convenient):

```ruby
test "marketing nav shows holiday menu link only when one is active" do
  Setting.holiday_menu_id = nil
  get "/about"
  assert_select "a.marketing-nav-holiday", count: 0

  holiday = Menu.create!(name: "Holiday Test", week_id: "26w50", menu_type: "holiday")
  Setting.holiday_menu_id = holiday.id

  get "/about"
  assert_select "a.marketing-nav-holiday", text: "Holiday Test"
ensure
  Setting.holiday_menu_id = nil
  holiday&.destroy
end
```

- [ ] **Step 7: Run all marketing tests**

```bash
bin/rails test test/controllers/about_controller_test.rb test/helpers/marketing_helper_test.rb
```

Expected: All pass.

- [ ] **Step 8: Commit**

```bash
git add app/helpers/marketing_helper.rb test/helpers/marketing_helper_test.rb app/views/layouts/_marketing_header.html.erb test/controllers/about_controller_test.rb
git commit -m "Surface active holiday menu in marketing nav via helper"
```

---

### Task 13: Port `/` (home) — rewrite HomeController to render

This is the cutover for the home page. Until now `/` redirected to `/menu`; after this commit it shows the marketing home for everyone (logged-in users still click "Order" to reach `/menu`).

**Files:**
- Modify: `app/controllers/home_controller.rb`
- Modify: `test/controllers/home_controller_test.rb`
- Create: `app/views/home/show.html.erb`

- [ ] **Step 1: Read the existing home controller test**

```bash
bin/rails test test/controllers/home_controller_test.rb -v
```

Note what's currently asserted (likely a redirect to `/menu`). The test will need to change to assert a 200 + content render.

- [ ] **Step 2: Rewrite the failing test**

Replace `test/controllers/home_controller_test.rb` with:

```ruby
require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "renders the marketing home for logged-out visitor" do
    get "/"
    assert_response :success
    assert_select "body.marketing"
    assert_select "h1, h2", text: /Community Bakery/i
  end

  test "renders the marketing home for logged-in user" do
    sign_in users(:kyle)
    get "/"
    assert_response :success
    assert_select "body.marketing"
  end

  test "signout still works" do
    sign_in users(:kyle)
    get "/signout"
    assert_redirected_to "/"
  end
end
```

- [ ] **Step 3: Run, expect failure**

```bash
bin/rails test test/controllers/home_controller_test.rb
```

Expected: First two tests fail (the controller still redirects).

- [ ] **Step 4: Rewrite HomeController**

Replace `app/controllers/home_controller.rb`:

```ruby
class HomeController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!

  def show
  end

  def signout
    sign_out :user
    redirect_to "/"
  end
end
```

- [ ] **Step 5: Create the home view**

Create `app/views/home/show.html.erb` (substitute image URLs from `marketing-assets-map.md`):

```erb
<% content_for :title, nil  # use site default title %>

<section class="hero">
  <div class="hero-image">
    <img src="<%# REPLACE WITH HERO S3 URL %>" alt="Motzi bread loaves">
  </div>
  <div class="hero-text">
    <h1>Community Bakery</h1>
    <p class="hero-tag">Locally Grown Grains · Freshly Milled Flour</p>
  </div>
</section>

<section class="find-us">
  <h2>Find Us Here</h2>
  <p>Our storefront at <strong>2801 Guilford Ave</strong></p>
  <ul>
    <li>Thursday/Friday — noon to 6pm</li>
    <li>Saturday — 9am to 2pm</li>
  </ul>
  <p>Or the <strong>32nd St Farmers' Market in Waverly</strong>, Saturday 7am – noon.</p>

  <h3>Retail Partners</h3>
  <ul>
    <li>The Wine Source — Hampden</li>
    <li>Chesapeake Farm to Table</li>
  </ul>

  <h3>Restaurants</h3>
  <ul>
    <li>Le Comptoir du Vin</li>
    <li>Dutch Courage</li>
    <li>Woodberry Kitchen</li>
  </ul>
</section>

<section class="subscriptions-cta">
  <h2>Subscriptions</h2>
  <p>Subscribe today! Our subscriptions are a great way to support your local bakery and pay less per loaf.</p>
  <p><a href="/subscribe" class="cta-primary">Learn more</a></p>
</section>

<section class="your-neighbors">
  <h2>Your Neighbors</h2>
  <p>We're <strong>Maya Muñoz and Russell Trimmer</strong>, bakers and owners.</p>
  <p><a href="/about">About us &rarr;</a></p>
</section>
```

- [ ] **Step 6: Run home tests, expect pass**

```bash
bin/rails test test/controllers/home_controller_test.rb
```

- [ ] **Step 7: Manual smoke test**

```bash
DISABLE_SPRING=1 bin/rails s -p 3000
```

Visit `http://localhost:3000/`. Expect: marketing home renders (no redirect to `/menu`). Click "Order" — should land on `/menu`. Click "Our Process" / "Subscriptions" / "Contact Us" — should each render. Sign in via `/dev/login_as_admin`, return to `/`. Expect: home still renders, plus an "Admin" link in the nav. Sign out via `/signout` — expect redirect back to `/`.

Stop the server.

- [ ] **Step 8: Run the full Rails suite**

```bash
bin/rails test
```

Expected: All pass.

- [ ] **Step 9: Commit**

```bash
git add app/controllers/home_controller.rb test/controllers/home_controller_test.rb app/views/home/show.html.erb
git commit -m "Replace home redirect with marketing home page (cutover from Wix)"
```

---

### Task 14: Visual QA via Playwright

Reuses the existing email-screenshots pattern (Playwright + Claude Haiku visual review). Not in CI — run locally before deploy and after any layout/SCSS change.

**Files:**
- Create: `test/visual/marketing-screenshots.spec.ts`
- Create: `test/visual/marketing-check-prompt.txt`

- [ ] **Step 1: Read the existing email visual test as a template**

```bash
cat test/visual/email-screenshots.spec.ts
cat test/visual/email-check-prompt.txt
```

Note the structure: it loops over a list of routes, screenshots each, sends the screenshot to Haiku with a prompt, asserts no critical issues.

- [ ] **Step 2: Write the marketing visual prompt**

Create `test/visual/marketing-check-prompt.txt`:

```
You are reviewing a screenshot of a marketing page on the motzibread.com website
that we just migrated from Wix to a Rails-based site.

Look for problems that would embarrass us in front of a customer. Specifically:
- Overlapping text or images
- Text clipped at viewport edges
- Broken images (alt text or 404 image icon visible)
- Misaligned or floating elements that should be flush with their column
- Typography that looks broken (missing font fallbacks, mismatched sizes)
- Buttons or links that look unstyled (default-blue underline, default-gray button)

Do NOT flag:
- Aesthetic preferences (this is a faithful port, not a redesign)
- Differences from the original Wix site as long as the page is readable
- Color choices

Reply in this format:
STATUS: ok | warning | broken
ISSUES:
- (one issue per bullet, or "none")
```

- [ ] **Step 3: Write the spec**

Create `test/visual/marketing-screenshots.spec.ts` (copy the structure from `email-screenshots.spec.ts` and adapt — example skeleton below; details depend on the existing helper functions used by the email spec):

```typescript
import { test, expect } from "@playwright/test";
import { readFileSync } from "node:fs";
import path from "node:path";
import Anthropic from "@anthropic-ai/sdk";

const PAGES = [
  { name: "home",      path: "/" },
  { name: "about",     path: "/about" },
  { name: "subscribe", path: "/subscribe" },
  { name: "contact",   path: "/contact" },
];

const PROMPT = readFileSync(
  path.join(__dirname, "marketing-check-prompt.txt"),
  "utf-8"
);

const client = new Anthropic();

for (const page of PAGES) {
  test(`marketing visual QA: ${page.name}`, async ({ page: pwPage }) => {
    await pwPage.goto(`http://localhost:3000${page.path}`);
    await pwPage.waitForLoadState("networkidle");

    const screenshotPath = path.join(
      __dirname,
      "screenshots",
      `marketing-${page.name}-${pwPage.viewportSize()?.width}.png`
    );
    const buffer = await pwPage.screenshot({ fullPage: true, path: screenshotPath });

    const result = await client.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 600,
      messages: [{
        role: "user",
        content: [
          { type: "image", source: { type: "base64", media_type: "image/png", data: buffer.toString("base64") } },
          { type: "text", text: PROMPT },
        ],
      }],
    });

    const text = (result.content[0] as { text: string }).text;
    console.log(`\n=== ${page.name} (${pwPage.viewportSize()?.width}px) ===\n${text}\n`);

    expect(text, `Visual review flagged ${page.name} as broken`).not.toMatch(/STATUS:\s*broken/i);
  });
}
```

If the existing email spec uses helper functions for the Anthropic call or screenshot management, refactor to share them.

- [ ] **Step 4: Start the Rails server in another terminal**

```bash
DISABLE_SPRING=1 bin/rails s -p 3000
```

- [ ] **Step 5: Run the visual tests**

```bash
bunx playwright test test/visual/marketing-screenshots.spec.ts
```

Expected: 8 tests pass (4 pages × 2 viewports). Read the console output for each — `STATUS: ok` or `STATUS: warning`. If anything is `broken`, fix it before proceeding.

- [ ] **Step 6: Commit**

```bash
git add test/visual/marketing-screenshots.spec.ts test/visual/marketing-check-prompt.txt
git commit -m "Add Playwright + Claude Haiku visual QA for marketing pages"
```

---

### Task 15: Deploy + verify in production

- [ ] **Step 1: Run typecheck and full test suite**

```bash
bun run typecheck
bin/rails test
bun test
```

Expected: All green.

- [ ] **Step 2: Push to master**

```bash
git push origin master
```

- [ ] **Step 3: Watch CI**

```bash
gh run list --branch master --limit 5 --json databaseId,status --jq '.[] | select(.status != "completed") | .databaseId' | xargs -I{} gh run watch {} --exit-status
```

- [ ] **Step 4: Set CONTACT_INBOX on Heroku**

```bash
heroku config:set CONTACT_INBOX=<bakery-email-address> --app motzibread
```

(Confirm the inbox address with kyle/Maya/Russell before running.)

- [ ] **Step 5: Verify in prod**

After Heroku auto-deploys, visit:
- `https://motzibread.herokuapp.com/` — marketing home
- `https://motzibread.herokuapp.com/about` — process page
- `https://motzibread.herokuapp.com/subscribe` — subscriptions
- `https://motzibread.herokuapp.com/contact` — submit a test message; confirm it lands in `/admin/contact_messages` and that the bakery inbox receives the email.

- [ ] **Step 6: Open follow-up issues**

Use the `issue` skill (or `gh issue create`) to capture:
- "Phase 2: DNS cutover — point motzibread.com at Heroku"
- "Retire motzibread.square.site once holiday menus run through the app"
- "Content audit with Maya/Russell — phone, hours, retail partners may be stale"

---

## Self-Review

**Spec coverage check:**

| Spec section | Implemented in |
|---|---|
| 4 pages render at `/`, `/about`, `/subscribe`, `/contact` | Tasks 3, 6, 7, 8, 13 |
| Per-page singular controllers | Task 3 (about/subscribe/contact), Task 13 (home) |
| `marketing.html.erb` layout, separate from `application.html.erb` | Task 3 |
| Marketing SCSS scoped under `.marketing` | Tasks 3, 4 |
| ContactMessage model + validations | Task 1 |
| ContactMessage ActiveAdmin (read-only triage) | Task 2 (uses `actions :index, :show, :destroy`) |
| ContactController#create persists + emails | Tasks 9, 10 |
| ContactMailer (text-only, Reply-To = submitter) | Task 10 |
| rack-attack throttle 5/hr/IP for POST /contact | Task 11 |
| Honeypot field on contact form | Task 9 |
| Asset rake task → S3 `public/marketing/` | Task 5 |
| Holiday menu nav link via `Menu.current_holiday` | Task 12 |
| Logged-in users see Account / Admin nav links | Task 3 (header partial) |
| HomeController#show rewritten from redirect | Task 13 |
| Visual QA via Playwright + Haiku | Task 14 |
| Deploy + verify | Task 15 |

No gaps.

**Placeholder scan:** the `<%# REPLACE WITH S3 URL %>` markers in Tasks 6 and 13 are intentional — they're filled from the `marketing-assets-map.md` produced in Task 5. The "Substitute the placeholder font names" instruction in Task 4 is intentional too — it can't be filled without DevTools inspection.

**Type / signature consistency:** `ContactMessage` field names (`name`, `email`, `phone`, `message`, `ip`, `user_agent`) used consistently across migration (Task 1), validations (Task 1), strong params (Task 9), mailer (Task 10), and admin (Task 2). `holiday_menu_link` helper signature consistent across helper test (Task 12 step 1), implementation (step 3), and view usage (step 5).
