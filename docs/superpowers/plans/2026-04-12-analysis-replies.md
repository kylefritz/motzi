# Analysis Replies Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let Kyle reply to the weekly Activity Report email and have those replies stored as `AnalysisReply` records that get fed back into next week's analysis prompt.

**Architecture:** Cloudflare Email Worker on `thepuff.co` receives replies at `reply+analysis-{id}@thepuff.co`, verifies SPF/DKIM, and POSTs parsed JSON to a Motzi webhook (`/reply_ingress`) authenticated via shared secret. Motzi validates the sender is an admin user and creates an `AnalysisReply` tied to the analysis. Prior analyses shown to Claude now include their operator replies inline.

**Note on thepuff.co:** `r.thepuff.co/*` is already in use by the corridor redirect worker (separate repo). This feature uses Cloudflare **Email Routing**, which is independent of HTTP routing and coexists with the existing redirect worker.

**Tech Stack:** Rails 7.2 + Postgres (Motzi), Cloudflare Email Workers + Wrangler + TypeScript (worker).

---

## File Structure

### Rails side (motzi)
- **Create:** `db/migrate/YYYYMMDDHHMMSS_create_analysis_replies.rb` — new table
- **Create:** `app/models/analysis_reply.rb` — model with validations and enum
- **Modify:** `app/models/anomaly_analysis.rb` — add `has_many :replies`
- **Modify:** `app/mailers/anomaly_mailer.rb` — add `reply_to` header
- **Modify:** `app/services/anomaly_detector.rb` — include replies in prompt
- **Create:** `app/controllers/reply_ingress_controller.rb` — webhook endpoint
- **Modify:** `config/routes.rb` — add POST `/reply_ingress`
- **Modify:** `app/admin/activity_feed.rb` — show replies under each analysis
- **Create:** `test/models/analysis_reply_test.rb`
- **Create:** `test/controllers/reply_ingress_controller_test.rb`
- **Modify:** `test/mailers/anomaly_mailer_test.rb` — existing file, add reply_to assertion
- **Modify:** `test/services/anomaly_detector_integration_test.rb` — add replies-in-prompt test

### Worker side (motzi repo, new subdirectory)
- **Create:** `cloudflare/workers/CLAUDE.md` — worker conventions
- **Create:** `cloudflare/workers/reply-ingress/wrangler.toml`
- **Create:** `cloudflare/workers/reply-ingress/package.json`
- **Create:** `cloudflare/workers/reply-ingress/tsconfig.json`
- **Create:** `cloudflare/workers/reply-ingress/src/index.ts`
- **Create:** `cloudflare/workers/reply-ingress/README.md` — deploy steps

---

## Task 1: Create `analysis_replies` table

**Files:**
- Create: `db/migrate/<timestamp>_create_analysis_replies.rb`

- [ ] **Step 1: Generate the migration**

Run: `DISABLE_SPRING=1 bin/rails generate migration CreateAnalysisReplies`

Expected: creates a file under `db/migrate/`.

- [ ] **Step 2: Write the migration body**

Replace the generated file contents with:

```ruby
class CreateAnalysisReplies < ActiveRecord::Migration[7.2]
  def change
    create_table :analysis_replies do |t|
      t.references :anomaly_analysis, null: false, foreign_key: true, index: true
      t.references :user, null: true, foreign_key: true, index: true
      t.string :author_email, null: false
      t.string :author_name
      t.text :body, null: false
      t.string :message_id
      t.integer :source, null: false, default: 0

      t.timestamps
    end

    add_index :analysis_replies, :message_id, unique: true
  end
end
```

- [ ] **Step 3: Run the migration**

Run: `DISABLE_SPRING=1 bin/rails db:migrate`
Expected: `== CreateAnalysisReplies: migrated (...) ==` and `db/schema.rb` updated.

- [ ] **Step 4: Commit**

```bash
git add db/migrate/*_create_analysis_replies.rb db/schema.rb
git commit -m "Create analysis_replies table

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: `AnalysisReply` model

**Files:**
- Create: `app/models/analysis_reply.rb`
- Create: `test/models/analysis_reply_test.rb`
- Create: `test/fixtures/analysis_replies.yml`
- Create: `test/fixtures/anomaly_analyses.yml` (if missing — check first)

- [ ] **Step 1: Check if anomaly_analyses fixtures exist**

Run: `ls test/fixtures/anomaly_analyses.yml 2>&1`

If the file does NOT exist, create it with:

```yaml
week1_analysis:
  week_id: 19w01
  result: |
    Status: ✅ Healthy
    Everything looks fine this week.
  trigger: scheduled
  model_used: claude-sonnet-4-6
  input_tokens: 1000
  output_tokens: 200
  cost_cents: 10
```

If the file exists, read it to see available fixtures and use one of them in Step 3.

- [ ] **Step 2: Write the failing test**

Create `test/models/analysis_reply_test.rb`:

```ruby
require 'test_helper'

class AnalysisReplyTest < ActiveSupport::TestCase
  test "valid with all required attributes" do
    reply = AnalysisReply.new(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com",
      body: "R14 isn't an error, ignore it.",
      source: :email
    )
    assert reply.valid?
  end

  test "invalid without body" do
    reply = AnalysisReply.new(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com"
    )
    refute reply.valid?
    assert_includes reply.errors[:body], "can't be blank"
  end

  test "invalid without author_email" do
    reply = AnalysisReply.new(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      body: "Some feedback"
    )
    refute reply.valid?
    assert_includes reply.errors[:author_email], "can't be blank"
  end

  test "enforces unique message_id when present" do
    AnalysisReply.create!(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com",
      body: "First",
      message_id: "<abc123@gmail.com>"
    )
    dup = AnalysisReply.new(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com",
      body: "Dup",
      message_id: "<abc123@gmail.com>"
    )
    refute dup.valid?
  end

  test "allows multiple replies with null message_id" do
    AnalysisReply.create!(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com",
      body: "First"
    )
    second = AnalysisReply.new(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com",
      body: "Second"
    )
    assert second.valid?
  end

  test "source enum" do
    reply = AnalysisReply.new(source: :email)
    assert reply.email?
    reply.source = :admin
    assert reply.admin?
  end
end
```

- [ ] **Step 3: Run the test — expect failure**

Run: `DISABLE_SPRING=1 bundle exec rails test test/models/analysis_reply_test.rb`
Expected: errors about `AnalysisReply` constant being undefined.

- [ ] **Step 4: Create the model**

Create `app/models/analysis_reply.rb`:

```ruby
class AnalysisReply < ApplicationRecord
  belongs_to :anomaly_analysis
  belongs_to :user, optional: true

  validates :body, :author_email, presence: true
  validates :message_id, uniqueness: true, allow_nil: true

  enum :source, { email: 0, admin: 1 }
end
```

- [ ] **Step 5: Run the tests — expect pass**

Run: `DISABLE_SPRING=1 bundle exec rails test test/models/analysis_reply_test.rb`
Expected: `5 runs, ...assertions, 0 failures, 0 errors`.

- [ ] **Step 6: Commit**

```bash
git add app/models/analysis_reply.rb test/models/analysis_reply_test.rb test/fixtures/
git commit -m "Add AnalysisReply model

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Add `has_many :replies` to `AnomalyAnalysis`

**Files:**
- Modify: `app/models/anomaly_analysis.rb`
- Create: `test/models/anomaly_analysis_test.rb` (or modify if exists)

- [ ] **Step 1: Check if a test file exists**

Run: `ls test/models/anomaly_analysis_test.rb 2>&1`

If the file exists, you'll add a test to it. If not, create a new test file.

- [ ] **Step 2: Write the failing test**

Create or add to `test/models/anomaly_analysis_test.rb`:

```ruby
require 'test_helper'

class AnomalyAnalysisTest < ActiveSupport::TestCase
  test "has many replies ordered by created_at" do
    analysis = anomaly_analyses(:week1_analysis)
    first = analysis.replies.create!(author_email: "kyle@example.com", body: "first", created_at: 2.hours.ago)
    second = analysis.replies.create!(author_email: "kyle@example.com", body: "second", created_at: 1.hour.ago)

    assert_equal [first, second], analysis.replies.to_a
  end

  test "destroys replies when analysis is destroyed" do
    analysis = anomaly_analyses(:week1_analysis)
    analysis.replies.create!(author_email: "kyle@example.com", body: "bye")

    assert_difference "AnalysisReply.count", -1 do
      analysis.destroy
    end
  end
end
```

- [ ] **Step 3: Run the tests — expect failure**

Run: `DISABLE_SPRING=1 bundle exec rails test test/models/anomaly_analysis_test.rb`
Expected: `NoMethodError: undefined method 'replies' for ...`.

- [ ] **Step 4: Add the association**

Edit `app/models/anomaly_analysis.rb` — add this line near the other `belongs_to` at the top:

```ruby
has_many :replies, -> { order(:created_at) }, class_name: "AnalysisReply", dependent: :destroy
```

- [ ] **Step 5: Run the tests — expect pass**

Run: `DISABLE_SPRING=1 bundle exec rails test test/models/anomaly_analysis_test.rb`
Expected: `2 runs, ... 0 failures, 0 errors`.

- [ ] **Step 6: Commit**

```bash
git add app/models/anomaly_analysis.rb test/models/anomaly_analysis_test.rb
git commit -m "AnomalyAnalysis has_many :replies

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Set `Reply-To` header on anomaly report emails

**Files:**
- Modify: `app/mailers/anomaly_mailer.rb`
- Modify: `test/mailers/anomaly_mailer_test.rb`

- [ ] **Step 1: Read the current mailer test**

Run: `cat test/mailers/anomaly_mailer_test.rb`

Note the existing structure so you add your test alongside existing tests.

- [ ] **Step 2: Add a failing test**

Add this test to `test/mailers/anomaly_mailer_test.rb` inside the test class:

```ruby
test "sets Reply-To with analysis ID for replies" do
  analysis = anomaly_analyses(:week1_analysis)
  email = AnomalyMailer.with(analysis: analysis).anomaly_report

  assert_equal ["reply+analysis-#{analysis.id}@thepuff.co"], email.reply_to
end
```

- [ ] **Step 3: Run the test — expect failure**

Run: `DISABLE_SPRING=1 bundle exec rails test test/mailers/anomaly_mailer_test.rb`
Expected: the new test fails because `reply_to` is nil.

- [ ] **Step 4: Update the mailer**

Edit `app/mailers/anomaly_mailer.rb`:

```ruby
class AnomalyMailer < ApplicationMailer
  REPLY_DOMAIN = "thepuff.co".freeze

  def anomaly_report
    @analysis = params[:analysis]
    mail(to: User.kyle.email_list,
         reply_to: "reply+analysis-#{@analysis.id}@#{REPLY_DOMAIN}",
         subject: "#{@analysis.status_emoji} #{@analysis.overall_status.capitalize} — #{@analysis.week_id} Motzi Activity Report") do |format|
      format.text
      format.mjml
    end
  end
end
```

- [ ] **Step 5: Run the tests — expect pass**

Run: `DISABLE_SPRING=1 bundle exec rails test test/mailers/anomaly_mailer_test.rb`
Expected: all tests pass, 0 failures, 0 errors.

- [ ] **Step 6: Commit**

```bash
git add app/mailers/anomaly_mailer.rb test/mailers/anomaly_mailer_test.rb
git commit -m "Set Reply-To header on anomaly report emails

Replies to the weekly Activity Report go to
reply+analysis-{id}@thepuff.co, which a Cloudflare Email Worker
will parse and forward back to Motzi.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: `ReplyIngressController` — happy path

**Files:**
- Create: `app/controllers/reply_ingress_controller.rb`
- Modify: `config/routes.rb`
- Create: `test/controllers/reply_ingress_controller_test.rb`

- [ ] **Step 1: Check user fixture for an admin**

Run: `grep -A3 'is_admin: true' test/fixtures/users.yml | head -20`

Note which user has `is_admin: true` — we'll reference them in tests. If `users(:kyle)` is already admin, use that.

- [ ] **Step 2: Write the failing test for happy path**

Create `test/controllers/reply_ingress_controller_test.rb`:

```ruby
require 'test_helper'

class ReplyIngressControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test-secret-123"
    ENV["REPLY_WEBHOOK_SECRET"] = @secret
    @analysis = anomaly_analyses(:week1_analysis)
    @admin = users(:kyle)  # kyle fixture is an admin
  end

  teardown do
    ENV.delete("REPLY_WEBHOOK_SECRET")
  end

  def auth_headers
    { "Authorization" => "Bearer #{@secret}", "Content-Type" => "application/json" }
  end

  test "creates a reply for an admin sender" do
    assert_difference "AnalysisReply.count", 1 do
      post "/reply_ingress",
        params: {
          analysis_id: @analysis.id,
          from_email: @admin.email,
          from_name: @admin.name,
          body: "R14 isn't an error. Please stop flagging it.",
          message_id: "<unique-id-1@gmail.com>"
        }.to_json,
        headers: auth_headers
    end

    assert_response :created
    reply = AnalysisReply.last
    assert_equal @analysis, reply.anomaly_analysis
    assert_equal @admin, reply.user
    assert_equal @admin.email, reply.author_email
    assert_equal "<unique-id-1@gmail.com>", reply.message_id
    assert reply.email?
  end
end
```

- [ ] **Step 3: Add the route**

Edit `config/routes.rb` — add this line inside the `Rails.application.routes.draw do` block (near the other top-level routes, not inside any scope):

```ruby
  post "/reply_ingress", to: "reply_ingress#create"
```

- [ ] **Step 4: Run the test — expect failure**

Run: `DISABLE_SPRING=1 bundle exec rails test test/controllers/reply_ingress_controller_test.rb`
Expected: `uninitialized constant ReplyIngressController`.

- [ ] **Step 5: Create the controller (happy path only)**

Create `app/controllers/reply_ingress_controller.rb`:

```ruby
class ReplyIngressController < ActionController::API
  before_action :authenticate!

  def create
    analysis = AnomalyAnalysis.find_by(id: params[:analysis_id])
    return render json: { error: "Unknown analysis" }, status: :not_found unless analysis

    author_email = params[:from_email].to_s.downcase
    user = User.find_by("LOWER(email) = ?", author_email)

    unless user&.is_admin?
      return render json: { error: "Sender not authorized" }, status: :forbidden
    end

    reply = analysis.replies.create!(
      user: user,
      author_email: author_email,
      author_name: params[:from_name],
      body: strip_quoted(params[:body]),
      message_id: params[:message_id],
      source: :email
    )

    render json: { id: reply.id }, status: :created
  rescue ActiveRecord::RecordNotUnique
    render json: { status: "duplicate" }, status: :ok
  end

  private

  def authenticate!
    expected = ENV["REPLY_WEBHOOK_SECRET"].to_s
    token = request.headers["Authorization"].to_s.sub(/^Bearer /, "")
    return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def strip_quoted(body)
    body.to_s.split(/\n(On .+ wrote:|>.*|-+Original Message-+)/m).first.to_s.strip
  end
end
```

- [ ] **Step 6: Run the test — expect pass**

Run: `DISABLE_SPRING=1 bundle exec rails test test/controllers/reply_ingress_controller_test.rb`
Expected: `1 runs, ... 0 failures, 0 errors`.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/reply_ingress_controller.rb config/routes.rb test/controllers/reply_ingress_controller_test.rb
git commit -m "Add ReplyIngressController happy path

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: `ReplyIngressController` — rejection cases

**Files:**
- Modify: `test/controllers/reply_ingress_controller_test.rb`

The controller already handles these cases from Task 5 — this task just adds tests to lock them in.

- [ ] **Step 1: Add the failing tests**

Append these tests to `test/controllers/reply_ingress_controller_test.rb` inside the class:

```ruby
test "401 without auth header" do
  post "/reply_ingress",
    params: { analysis_id: @analysis.id }.to_json,
    headers: { "Content-Type" => "application/json" }

  assert_response :unauthorized
end

test "401 with wrong secret" do
  post "/reply_ingress",
    params: { analysis_id: @analysis.id }.to_json,
    headers: { "Authorization" => "Bearer nope", "Content-Type" => "application/json" }

  assert_response :unauthorized
end

test "404 when analysis does not exist" do
  post "/reply_ingress",
    params: {
      analysis_id: 999_999,
      from_email: @admin.email,
      body: "hi"
    }.to_json,
    headers: auth_headers

  assert_response :not_found
end

test "403 when sender is not an admin" do
  non_admin = users(:jess)
  assert_not non_admin.is_admin?, "jess fixture should not be admin"

  assert_no_difference "AnalysisReply.count" do
    post "/reply_ingress",
      params: {
        analysis_id: @analysis.id,
        from_email: non_admin.email,
        body: "hi"
      }.to_json,
      headers: auth_headers
  end

  assert_response :forbidden
end

test "403 when sender email is unknown" do
  assert_no_difference "AnalysisReply.count" do
    post "/reply_ingress",
      params: {
        analysis_id: @analysis.id,
        from_email: "randomstranger@example.com",
        body: "hi"
      }.to_json,
      headers: auth_headers
  end

  assert_response :forbidden
end

test "duplicate message_id returns 200 idempotent" do
  payload = {
    analysis_id: @analysis.id,
    from_email: @admin.email,
    body: "first",
    message_id: "<dup@example.com>"
  }
  post "/reply_ingress", params: payload.to_json, headers: auth_headers
  assert_response :created

  assert_no_difference "AnalysisReply.count" do
    post "/reply_ingress", params: payload.to_json, headers: auth_headers
  end

  assert_response :ok
  json = JSON.parse(response.body)
  assert_equal "duplicate", json["status"]
end

test "strips quoted reply history from body" do
  body_with_quote = <<~BODY
    Here is my new thought.

    On Sun, Apr 12, 2026 at 9:00 PM Motzi <no-reply@motzi.com> wrote:
    > old stuff
    > more old stuff
  BODY

  post "/reply_ingress",
    params: {
      analysis_id: @analysis.id,
      from_email: @admin.email,
      body: body_with_quote,
      message_id: "<strip-test@example.com>"
    }.to_json,
    headers: auth_headers

  assert_response :created
  reply = AnalysisReply.last
  assert_equal "Here is my new thought.", reply.body
end
```

- [ ] **Step 2: Run the tests — expect pass (all handled by controller from Task 5)**

Run: `DISABLE_SPRING=1 bundle exec rails test test/controllers/reply_ingress_controller_test.rb`
Expected: all tests pass, 0 failures, 0 errors.

If any fail, adjust the controller — but the Task 5 implementation should cover all of these.

- [ ] **Step 3: Commit**

```bash
git add test/controllers/reply_ingress_controller_test.rb
git commit -m "Test rejection cases for ReplyIngressController

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Include replies in `AnomalyDetector` prompt

**Files:**
- Modify: `app/services/anomaly_detector.rb`
- Modify: `test/services/anomaly_detector_integration_test.rb`

- [ ] **Step 1: Inspect the existing integration test**

Run: `sed -n '1,40p' test/services/anomaly_detector_integration_test.rb`

Note the class name and how it builds prompts — you'll add a test that checks replies appear.

- [ ] **Step 2: Write the failing test**

Append this test to `test/services/anomaly_detector_integration_test.rb` inside the test class:

```ruby
test "build_user_message includes replies alongside prior analyses" do
  # Create a prior analysis (for a week before the current test week)
  prior_week_id = "19w01"  # matches week1_analysis fixture
  prior = anomaly_analyses(:week1_analysis)
  prior.replies.create!(
    author_email: "kyle@example.com",
    author_name: "Kyle Fritz",
    body: "R14 is expected — please stop flagging it.",
    source: :email
  )

  # Build the prompt for some later week that would include prior_week as comparison.
  # Use the week_id from the latest existing analysis if fixtures differ.
  detector = AnomalyDetector.new(prior_week_id)
  message = detector.build_user_message

  # The reply body should appear somewhere in the prompt
  assert_includes message, "R14 is expected",
    "expected reply body to appear in the prompt"
  assert_includes message, "Operator replies",
    "expected an Operator replies heading"
end
```

Note: if `build_user_message` is private, the test will need `detector.send(:build_user_message)`. Check the method visibility first.

- [ ] **Step 3: Run the test — expect failure**

Run: `DISABLE_SPRING=1 bundle exec rails test test/services/anomaly_detector_integration_test.rb`
Expected: fails because the reply body isn't in the prompt.

- [ ] **Step 4: Update the detector**

Edit `app/services/anomaly_detector.rb`, find the `build_user_message` method's loop over `prior_analyses` (around line 94). Replace:

```ruby
    prior_analyses = recent_analyses
    if prior_analyses.any?
      @on_progress.call("Including #{prior_analyses.size} prior analyses for context…")
      parts << "---"
      parts << "## Prior Analyses (for context — avoid repeating resolved findings)"
      prior_analyses.each do |a|
        parts << ""
        parts << "### #{a.week_id} — #{a.created_at.strftime('%-m/%-d/%Y')} (#{a.trigger})"
        parts << a.result
      end
    end
```

With:

```ruby
    prior_analyses = recent_analyses
    if prior_analyses.any?
      @on_progress.call("Including #{prior_analyses.size} prior analyses for context…")
      parts << "---"
      parts << "## Prior Analyses (for context — avoid repeating resolved findings)"
      prior_analyses.each do |a|
        parts << ""
        parts << "### #{a.week_id} — #{a.created_at.strftime('%-m/%-d/%Y')} (#{a.trigger})"
        parts << a.result

        if a.replies.any?
          parts << ""
          parts << "**Operator replies:**"
          a.replies.each do |r|
            who = r.author_name.presence || r.author_email
            parts << "- #{who} (#{r.created_at.strftime('%-m/%-d')}): #{r.body}"
          end
        end
      end
    end
```

Also change `recent_analyses` (around line 131) to eager-load replies:

```ruby
  def recent_analyses
    AnomalyAnalysis.includes(:replies).order(created_at: :desc).limit(6).to_a.reverse
  end
```

- [ ] **Step 5: Run the test — expect pass**

Run: `DISABLE_SPRING=1 bundle exec rails test test/services/anomaly_detector_integration_test.rb`
Expected: all tests pass, 0 failures, 0 errors.

- [ ] **Step 6: Commit**

```bash
git add app/services/anomaly_detector.rb test/services/anomaly_detector_integration_test.rb
git commit -m "Include analysis replies in next week's prompt

Operator replies (from email ingress) appear inline under each
prior analysis in the prompt, so Claude sees operator guidance
like 'R14 isn't an error — stop flagging it' when producing
the next report.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Display replies in the admin Activity Feed page

**Files:**
- Modify: `app/admin/activity_feed.rb`

- [ ] **Step 1: Find the Claude Analyses panel**

Run: `grep -n 'Claude Analyses' app/admin/activity_feed.rb`

Expected: one line somewhere around line 534 — `panel "Claude Analyses" do`.

- [ ] **Step 2: Add replies rendering inside the analysis card**

In `app/admin/activity_feed.rb`, locate the block inside `panel "Claude Analyses" do` that renders each `analysis`. Find this existing code (search for `analysis-body`):

```ruby
            div class: "analysis-body" do
              text_node markdown.render(analysis.result).html_safe
            end
```

Add this block immediately AFTER the `analysis-body` div closes but BEFORE the `analysis-footer` div:

```ruby
            if analysis.replies.any?
              div class: "analysis-replies", style: "margin-top: 16px; padding-top: 12px; border-top: 1px solid #eee" do
                h4 "Replies (#{analysis.replies.size})", style: "margin: 0 0 8px; font-size: 13px; color: #666"
                analysis.replies.each do |reply|
                  div class: "analysis-reply", style: "margin-bottom: 10px; padding: 8px 12px; background: #f9f9fb; border-left: 3px solid #352C63; font-size: 13px" do
                    div style: "font-weight: 500; color: #352C63; margin-bottom: 4px" do
                      who = reply.author_name.presence || reply.author_email
                      text_node "#{who} · #{reply.created_at.strftime('%-m/%-d %l:%M%P').strip} · via #{reply.source}"
                    end
                    div style: "white-space: pre-wrap; color: #2E2927" do
                      text_node reply.body
                    end
                  end
                end
              end
            end
```

- [ ] **Step 3: Smoke test**

Run: `DISABLE_SPRING=1 bundle exec rails test` (full suite) to make sure nothing broke.
Expected: 0 failures, 0 errors.

No specific test for admin rendering — visual check only.

- [ ] **Step 4: Commit**

```bash
git add app/admin/activity_feed.rb
git commit -m "Show analysis replies in admin Activity Feed

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Cloudflare Worker scaffolding

**Files:**
- Create: `cloudflare/workers/CLAUDE.md`
- Create: `cloudflare/workers/reply-ingress/wrangler.toml`
- Create: `cloudflare/workers/reply-ingress/package.json`
- Create: `cloudflare/workers/reply-ingress/tsconfig.json`
- Create: `cloudflare/workers/reply-ingress/.gitignore`

- [ ] **Step 1: Create the workers directory and CLAUDE.md**

Create `cloudflare/workers/CLAUDE.md`:

```markdown
# Cloudflare Workers

Deployed via [Wrangler](https://developers.cloudflare.com/workers/wrangler/). Each subdirectory is a separate worker with its own `wrangler.toml`.

## Deploy

```bash
cd cloudflare/workers/<worker-name>
bun install
wrangler deploy
```

## Workers

### reply-ingress

Receives email replies at `reply+*@thepuff.co` via Cloudflare Email Routing. Extracts the analysis ID from the To address, verifies SPF/DKIM, parses the email body, and POSTs to the Motzi `/reply_ingress` endpoint with a shared secret. If Motzi rejects (or the email fails verification), the worker bounces the message back to the sender with an explanation.
```

- [ ] **Step 2: Create `wrangler.toml`**

Create `cloudflare/workers/reply-ingress/wrangler.toml`:

```toml
name = "motzi-reply-ingress"
main = "src/index.ts"
compatibility_date = "2024-10-01"

[vars]
MOTZI_URL = "https://motzibread.herokuapp.com"

# Secrets — set via: wrangler secret put REPLY_WEBHOOK_SECRET
# - REPLY_WEBHOOK_SECRET
```

- [ ] **Step 3: Create `package.json`**

Create `cloudflare/workers/reply-ingress/package.json`:

```json
{
  "name": "motzi-reply-ingress",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "deploy": "wrangler deploy",
    "dev": "wrangler dev",
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20240925.0",
    "typescript": "^5.5.0",
    "wrangler": "^3.80.0"
  },
  "dependencies": {
    "postal-mime": "^2.2.7"
  }
}
```

- [ ] **Step 4: Create `tsconfig.json`**

Create `cloudflare/workers/reply-ingress/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "es2022",
    "module": "es2022",
    "moduleResolution": "bundler",
    "lib": ["es2022"],
    "types": ["@cloudflare/workers-types"],
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*.ts"]
}
```

- [ ] **Step 5: Create `.gitignore`**

Create `cloudflare/workers/reply-ingress/.gitignore`:

```
node_modules/
.wrangler/
.dev.vars
```

- [ ] **Step 6: Commit scaffolding**

```bash
git add cloudflare/
git commit -m "Scaffold reply-ingress Cloudflare Email Worker

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Worker implementation

**Files:**
- Create: `cloudflare/workers/reply-ingress/src/index.ts`
- Create: `cloudflare/workers/reply-ingress/README.md`

- [ ] **Step 1: Install dependencies**

Run: `cd cloudflare/workers/reply-ingress && bun install`
Expected: `node_modules/` appears, `bun.lock` created.

- [ ] **Step 2: Create the worker source**

Create `cloudflare/workers/reply-ingress/src/index.ts`:

```typescript
import PostalMime from "postal-mime";

interface Env {
  MOTZI_URL: string;
  REPLY_WEBHOOK_SECRET: string;
}

interface MotziPayload {
  analysis_id: string;
  from_email: string;
  from_name?: string;
  body: string;
  message_id?: string;
  subject?: string;
}

export default {
  async email(message: ForwardableEmailMessage, env: Env, ctx: ExecutionContext): Promise<void> {
    try {
      // 1. Verify SPF and DKIM via Authentication-Results
      const authResults = message.headers.get("Authentication-Results") || "";
      const spfPass = /spf=pass/i.test(authResults);
      const dkimPass = /dkim=pass/i.test(authResults);
      if (!spfPass || !dkimPass) {
        message.setReject("SPF or DKIM verification failed");
        return;
      }

      // 2. Extract analysis_id from recipient address
      //    Example: reply+analysis-123@thepuff.co
      const match = message.to.match(/reply\+analysis-(\d+)@/i);
      if (!match) {
        message.setReject(`Unknown recipient: ${message.to}`);
        return;
      }
      const analysisId = match[1];

      // 3. Parse the email using postal-mime
      const raw = new Response(message.raw);
      const rawBuffer = await raw.arrayBuffer();
      const parsed = await PostalMime.parse(rawBuffer);

      const fromEmail = parsed.from?.address || "";
      const fromName = parsed.from?.name || "";
      const bodyText = parsed.text || "";

      if (!fromEmail || !bodyText) {
        message.setReject("Missing From address or body");
        return;
      }

      // 4. POST to Motzi
      const payload: MotziPayload = {
        analysis_id: analysisId,
        from_email: fromEmail,
        from_name: fromName,
        body: bodyText,
        message_id: parsed.messageId,
        subject: parsed.subject,
      };

      const response = await fetch(`${env.MOTZI_URL}/reply_ingress`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${env.REPLY_WEBHOOK_SECRET}`,
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        let reason = `Motzi rejected the reply (HTTP ${response.status})`;
        try {
          const json = (await response.json()) as { error?: string };
          if (json.error) reason = json.error;
        } catch {
          // ignore parse errors
        }
        message.setReject(reason);
      }
    } catch (err) {
      console.error("reply-ingress error", err);
      message.setReject("Internal worker error — check logs");
    }
  },
};
```

- [ ] **Step 3: Typecheck**

Run: `cd cloudflare/workers/reply-ingress && bun run typecheck`
Expected: no errors.

- [ ] **Step 4: Create README with deploy steps**

Create `cloudflare/workers/reply-ingress/README.md`:

```markdown
# motzi-reply-ingress

Cloudflare Email Worker that receives replies to the Motzi Activity Report emails and POSTs them to the Motzi Rails app.

## How it works

1. User replies to the weekly Activity Report email (Reply-To: `reply+analysis-{id}@thepuff.co`).
2. Cloudflare Email Routing forwards `reply+*@thepuff.co` to this worker.
3. Worker verifies SPF and DKIM passed, extracts the analysis ID, parses the email body using `postal-mime`, and POSTs JSON to `${MOTZI_URL}/reply_ingress` with a Bearer token.
4. Motzi validates the sender is an admin and creates an `AnalysisReply`.
5. If anything fails (SPF, DKIM, unknown analysis, non-admin sender, Motzi error), the worker calls `message.setReject(reason)` and Cloudflare bounces the email back to the sender.

## Deploy

```bash
cd cloudflare/workers/reply-ingress
bun install
wrangler login        # once
wrangler secret put REPLY_WEBHOOK_SECRET   # paste the same value as Heroku's REPLY_WEBHOOK_SECRET
wrangler deploy
```

Then in Cloudflare dashboard → thepuff.co → Email → Email Routing:
- Enable Email Routing if not already enabled
- Add a custom address rule: `reply+*@thepuff.co` → send to worker `motzi-reply-ingress`

## Testing

Send a real reply to a Motzi Activity Report email. Tail logs with `wrangler tail`.
```

- [ ] **Step 5: Commit worker implementation**

```bash
git add cloudflare/workers/reply-ingress/src/ cloudflare/workers/reply-ingress/README.md cloudflare/workers/reply-ingress/bun.lock
git commit -m "Implement reply-ingress email worker

Receives replies to reply+analysis-{id}@thepuff.co, verifies
SPF/DKIM, parses the MIME body, and forwards to Motzi's
/reply_ingress endpoint. Bounces the message with a reason
if Motzi rejects or verification fails.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: Deploy checklist doc

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add a section about the new env var and deploy steps**

Edit `CLAUDE.md` — add this section after the existing `## Deployment` section:

```markdown

## Analysis Replies (email ingress)

The weekly anomaly report emails have a `Reply-To` of `reply+analysis-{id}@thepuff.co`. A Cloudflare Email Worker (`cloudflare/workers/reply-ingress/`) receives replies and POSTs them to `/reply_ingress` on Motzi, where they get stored as `AnalysisReply` records and fed into next week's prompt.

**Required env var on Heroku:** `REPLY_WEBHOOK_SECRET` (shared with the worker)

Generate a new one: `ruby -rsecurerandom -e 'puts SecureRandom.hex(32)'`

Set on Heroku: `heroku config:set REPLY_WEBHOOK_SECRET=... --app motzibread`

Set on worker: `cd cloudflare/workers/reply-ingress && wrangler secret put REPLY_WEBHOOK_SECRET` (paste same value)

Worker deploy: `cd cloudflare/workers/reply-ingress && wrangler deploy`
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "Document analysis reply email ingress setup

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 12: Final full test run

- [ ] **Step 1: Run the full Rails test suite**

Run: `DISABLE_SPRING=1 bundle exec rails test`
Expected: 0 failures, 0 errors (should be around 346+ runs after our additions).

- [ ] **Step 2: Run JS tests**

Run: `bun test`
Expected: all pass.

- [ ] **Step 3: Typecheck**

Run: `bun run typecheck`
Expected: no errors.

- [ ] **Step 4: Worker typecheck**

Run: `cd cloudflare/workers/reply-ingress && bun run typecheck`
Expected: no errors.

- [ ] **Step 5: Push**

```bash
git push
```

Watch CI: `gh run list --branch master --limit 3 --json databaseId,status,conclusion`

- [ ] **Step 6: Manual deploy steps (not automated)**

These must be done by hand before the feature goes live:
1. Generate secret: `ruby -rsecurerandom -e 'puts SecureRandom.hex(32)'`
2. `heroku config:set REPLY_WEBHOOK_SECRET=... --app motzibread`
3. `cd cloudflare/workers/reply-ingress && wrangler deploy`
4. `wrangler secret put REPLY_WEBHOOK_SECRET` (paste same value)
5. In Cloudflare dashboard → thepuff.co → Email → Email Routing: create a catch-all rule or custom address `reply+*@thepuff.co` → worker `motzi-reply-ingress`
6. Wait for the next scheduled analysis email (or trigger manually via admin), then reply to it. Check admin Activity Feed for the reply.
7. If the reply didn't appear, tail worker logs: `cd cloudflare/workers/reply-ingress && wrangler tail`
