# Custom Error Pages with Feedback — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace default Rails error pages with branded Motzi-themed pages that include a user feedback form, store submissions in the database, and email Kyle on each report.

**Architecture:** Hybrid approach — 404/422 are controller-rendered using the application layout; 500 is static HTML with inline styles and a JS `fetch()` feedback form. A JSON API endpoint at `POST /api/error_feedbacks` handles all submissions with Turnstile verification. Emails use MJML templates matching the existing mailer design.

**Tech Stack:** Rails 7.2, Bootstrap 4, SCSS, MJML (via mjml-rails/mrml), ActiveAdmin, Cloudflare Turnstile, Minitest

**Spec:** `docs/superpowers/specs/2026-03-23-custom-error-pages-design.md`

**Working directory:** `/Users/kyle/code/motzi/.worktrees/custom-error-pages`

---

### Task 1: Migration & Model

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_create_error_feedbacks.rb`
- Create: `app/models/error_feedback.rb`
- Create: `test/models/error_feedback_test.rb`

- [ ] **Step 1: Write the model test**

```ruby
# test/models/error_feedback_test.rb
require 'test_helper'

class ErrorFeedbackTest < ActiveSupport::TestCase
  test "valid with page_type and message" do
    feedback = ErrorFeedback.new(page_type: "404", message: "Page missing")
    assert feedback.valid?
  end

  test "invalid without page_type" do
    feedback = ErrorFeedback.new(message: "Page missing")
    assert_not feedback.valid?
    assert feedback.errors[:page_type].any?
  end

  test "invalid without message" do
    feedback = ErrorFeedback.new(page_type: "404")
    assert_not feedback.valid?
    assert feedback.errors[:message].any?
  end

  test "invalid with unknown page_type" do
    feedback = ErrorFeedback.new(page_type: "418", message: "I'm a teapot")
    assert_not feedback.valid?
    assert feedback.errors[:page_type].any?
  end

  test "valid page_types" do
    %w[404 422 500].each do |pt|
      feedback = ErrorFeedback.new(page_type: pt, message: "test")
      assert feedback.valid?, "#{pt} should be valid"
    end
  end

  test "email format validation" do
    feedback = ErrorFeedback.new(page_type: "404", message: "test", email: "not-an-email")
    assert_not feedback.valid?

    feedback.email = "user@example.com"
    assert feedback.valid?
  end

  test "email is optional" do
    feedback = ErrorFeedback.new(page_type: "404", message: "test")
    assert feedback.valid?
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `DISABLE_SPRING=1 bin/rails test test/models/error_feedback_test.rb`
Expected: Error — `ErrorFeedback` not defined, table doesn't exist

- [ ] **Step 3: Create the migration**

Run: `DISABLE_SPRING=1 bin/rails generate migration CreateErrorFeedbacks page_type:string message:text email:string url:string user_agent:string`

Then edit the generated migration to add constraints:

```ruby
class CreateErrorFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :error_feedbacks do |t|
      t.string :page_type, null: false
      t.text :message, null: false
      t.string :email
      t.string :url
      t.string :user_agent

      t.datetime :created_at, null: false
    end
  end
end
```

Note: No `updated_at` — these are write-once records.

- [ ] **Step 4: Create the model**

```ruby
# app/models/error_feedback.rb
class ErrorFeedback < ApplicationRecord
  validates :page_type, presence: true, inclusion: { in: %w[404 422 500] }
  validates :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
```

- [ ] **Step 5: Run migration and tests**

Run: `DISABLE_SPRING=1 bin/rails db:migrate && DISABLE_SPRING=1 bin/rails test test/models/error_feedback_test.rb`
Expected: All 7 tests pass

- [ ] **Step 6: Commit**

```bash
git add db/migrate/*_create_error_feedbacks.rb app/models/error_feedback.rb test/models/error_feedback_test.rb db/schema.rb
git commit -m "Add ErrorFeedback model with validations and tests"
```

---

### Task 2: Mailer

**Files:**
- Create: `app/mailers/error_feedback_mailer.rb`
- Create: `app/views/error_feedback_mailer/feedback_received.mjml`
- Create: `app/views/error_feedback_mailer/feedback_received.text.erb`
- Create: `test/mailers/error_feedback_mailer_test.rb`

- [ ] **Step 1: Write the mailer test**

```ruby
# test/mailers/error_feedback_mailer_test.rb
require 'test_helper'

class ErrorFeedbackMailerTest < ActionMailer::TestCase
  test "feedback_received" do
    feedback = ErrorFeedback.create!(
      page_type: "404",
      message: "I can't find the sourdough page",
      email: "customer@example.com",
      url: "/sourdough",
      user_agent: "Mozilla/5.0"
    )

    email = ErrorFeedbackMailer.with(feedback: feedback).feedback_received

    assert_emails 1 do
      email.deliver_now
    end

    assert_includes email.to, users(:kyle).email
    assert_equal "Error feedback from 404 page", email.subject

    # Text part
    text = email.text_part.body.to_s
    assert_includes text, "404"
    assert_includes text, "I can't find the sourdough page"
    assert_includes text, "customer@example.com"
    assert_includes text, "/sourdough"

    # HTML part
    html = email.html_part.body.to_s
    assert_includes html, "Error Feedback"
    assert_includes html, "404"
    assert_includes html, "sourdough"
    assert_includes html, "customer@example.com"
  end

  test "feedback_received without optional fields" do
    feedback = ErrorFeedback.create!(
      page_type: "500",
      message: "Everything is broken"
    )

    email = ErrorFeedbackMailer.with(feedback: feedback).feedback_received

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal "Error feedback from 500 page", email.subject
    text = email.text_part.body.to_s
    assert_includes text, "Everything is broken"
    refute_includes text, "Reply to:"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `DISABLE_SPRING=1 bin/rails test test/mailers/error_feedback_mailer_test.rb`
Expected: Error — `ErrorFeedbackMailer` not defined

- [ ] **Step 3: Create the mailer**

```ruby
# app/mailers/error_feedback_mailer.rb
class ErrorFeedbackMailer < ApplicationMailer
  def feedback_received
    @feedback = params[:feedback]
    mail(to: User.kyle.email_list,
         subject: "Error feedback from #{@feedback.page_type} page") do |format|
      format.text
      format.mjml
    end
  end
end
```

- [ ] **Step 4: Create the MJML template**

```erb
<%# app/views/error_feedback_mailer/feedback_received.mjml %>
<mjml>
  <mj-head>
    <%= render partial: "shared_mailer/head", formats: [:html] %>
  </mj-head>
  <mj-body background-color="#FFECD6" width="1200px">
    <%= render partial: "shared_mailer/header", formats: [:html] %>

    <mj-section background-color="#ffffff" padding="32px 40px 24px 40px">
      <mj-column>
        <mj-text padding="0 0 8px 0" font-size="13px" font-weight="500" letter-spacing="0.08em" text-transform="uppercase" color="#D5482C">
          Error Feedback
        </mj-text>

        <mj-text padding="0 0 20px 0" font-size="26px" font-weight="700" line-height="1.3" color="#352C63">
          <%= @feedback.page_type %> Page Report
        </mj-text>

        <mj-divider border-color="#D5482C" border-width="2px" padding="0 0 24px 0" />

        <mj-text padding="0 0 16px 0" font-size="15px" line-height="1.6" color="#2E2927">
          <strong>Message:</strong>
        </mj-text>

        <mj-text padding="16px 20px" background-color="#f7f0e8" border-radius="4px" font-size="14px" line-height="1.7" color="#2E2927">
          <%= @feedback.message %>
        </mj-text>

        <% if @feedback.email.present? %>
        <mj-text padding="20px 0 0 0" font-size="15px" line-height="1.6" color="#2E2927">
          <strong>Reply to:</strong> <a href="mailto:<%= @feedback.email %>"><%= @feedback.email %></a>
        </mj-text>
        <% end %>

        <mj-divider border-color="#e8e0d8" border-width="1px" padding="28px 0 16px 0" />

        <mj-text padding="0 0 4px 0" font-size="12px" line-height="1.5" color="#2E2927">
          <strong>Page:</strong> <%= @feedback.page_type %>
          <% if @feedback.url.present? %>&nbsp;&middot;&nbsp; <strong>URL:</strong> <%= @feedback.url %><% end %>
        </mj-text>

        <mj-text padding="0" font-size="12px" line-height="1.5" color="#2E2927">
          <strong>Submitted:</strong> <%= @feedback.created_at.strftime("%Y-%m-%d %l:%M%P %Z") %>
          <% if @feedback.user_agent.present? %>&nbsp;&middot;&nbsp; <strong>Browser:</strong> <%= truncate(@feedback.user_agent, length: 80) %><% end %>
        </mj-text>
      </mj-column>
    </mj-section>

    <%= render partial: "shared_mailer/footer", formats: [:html] %>
  </mj-body>
</mjml>
```

- [ ] **Step 5: Create the text template**

```erb
<%# app/views/error_feedback_mailer/feedback_received.text.erb %>
Error Feedback: <%= @feedback.page_type %> Page
<%= "=" * 40 %>

<%= @feedback.message %>

<% if @feedback.email.present? %>
Reply to: <%= @feedback.email %>
<% end %>
---
Page: <%= @feedback.page_type %>
<% if @feedback.url.present? %>URL: <%= @feedback.url %><% end %>
Submitted: <%= @feedback.created_at.strftime("%Y-%m-%d %l:%M%P %Z") %>
<% if @feedback.user_agent.present? %>Browser: <%= @feedback.user_agent %><% end %>
```

- [ ] **Step 6: Run tests**

Run: `DISABLE_SPRING=1 bin/rails test test/mailers/error_feedback_mailer_test.rb`
Expected: Both tests pass

- [ ] **Step 7: Commit**

```bash
git add app/mailers/error_feedback_mailer.rb app/views/error_feedback_mailer/ test/mailers/error_feedback_mailer_test.rb
git commit -m "Add ErrorFeedbackMailer with MJML and text templates"
```

---

### Task 3: API Endpoint

**Files:**
- Create: `app/controllers/api/error_feedbacks_controller.rb`
- Create: `test/controllers/api/error_feedbacks_controller_test.rb`
- Modify: `config/routes.rb`

- [ ] **Step 1: Write the controller test**

```ruby
# test/controllers/api/error_feedbacks_controller_test.rb
require 'test_helper'
require 'webmock/minitest'

class Api::ErrorFeedbacksControllerTest < ActionDispatch::IntegrationTest
  TURNSTILE_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  test "creates feedback and sends email" do
    stub_turnstile(success: true)

    assert_difference 'ErrorFeedback.count', 1 do
      assert_emails 1 do
        post api_error_feedbacks_path, params: {
          error_feedback: {
            page_type: "404",
            message: "Can't find sourdough",
            email: "customer@example.com",
            url: "/sourdough"
          },
          turnstile_token: "valid-token"
        }, as: :json
      end
    end

    assert_response :created
    feedback = ErrorFeedback.last
    assert_equal "404", feedback.page_type
    assert_equal "Can't find sourdough", feedback.message
    assert_equal "customer@example.com", feedback.email
    assert_equal "/sourdough", feedback.url
  end

  test "returns 422 with invalid params" do
    stub_turnstile(success: true)

    assert_no_difference 'ErrorFeedback.count' do
      post api_error_feedbacks_path, params: {
        error_feedback: { page_type: "404", message: "" },
        turnstile_token: "valid-token"
      }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "returns 403 with invalid turnstile token" do
    stub_turnstile(success: false)

    assert_no_difference 'ErrorFeedback.count' do
      post api_error_feedbacks_path, params: {
        error_feedback: { page_type: "404", message: "test" },
        turnstile_token: "invalid"
      }, as: :json
    end

    assert_response :forbidden
  end

  test "skips turnstile for 500 page without token" do
    assert_difference 'ErrorFeedback.count', 1 do
      post api_error_feedbacks_path, params: {
        error_feedback: {
          page_type: "500",
          message: "Everything broke"
        }
      }, as: :json
    end

    assert_response :created
  end

  test "captures user agent" do
    stub_turnstile(success: true)

    post api_error_feedbacks_path,
      params: {
        error_feedback: { page_type: "404", message: "test" },
        turnstile_token: "valid-token"
      },
      headers: { "User-Agent" => "TestBrowser/1.0" },
      as: :json

    assert_response :created
    assert_equal "TestBrowser/1.0", ErrorFeedback.last.user_agent
  end

  private

  def stub_turnstile(success:)
    stub_request(:post, TURNSTILE_URL)
      .to_return(body: { success: success }.to_json, headers: { "Content-Type" => "application/json" })
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `DISABLE_SPRING=1 bin/rails test test/controllers/api/error_feedbacks_controller_test.rb`
Expected: Error — route not found, controller not defined

- [ ] **Step 3: Add routes**

Edit `config/routes.rb` — add before the closing `end`:

```ruby
  # Error feedback API (used by error pages)
  namespace :api do
    resources :error_feedbacks, only: [:create]
  end
```

- [ ] **Step 4: Create the controller**

```ruby
# app/controllers/api/error_feedbacks_controller.rb
class Api::ErrorFeedbacksController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    unless skip_turnstile? || verify_turnstile
      return render json: { error: "Verification failed" }, status: :forbidden
    end

    feedback = ErrorFeedback.new(feedback_params)
    feedback.user_agent = request.user_agent

    if feedback.save
      ErrorFeedbackMailer.with(feedback: feedback).feedback_received.deliver_now
      render json: { success: true }, status: :created
    else
      render json: { error: feedback.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    params.require(:error_feedback).permit(:page_type, :message, :email, :url)
  end

  def verify_turnstile
    token = params[:turnstile_token]
    return false if token.blank?

    secret = ENV["TURNSTILE_SECRET_KEY"]
    return true if secret.blank? # Skip in dev/test if not configured

    response = Net::HTTP.post_form(
      URI("https://challenges.cloudflare.com/turnstile/v0/siteverify"),
      { secret: secret, response: token }
    )
    JSON.parse(response.body)["success"] == true
  rescue StandardError
    false
  end

  # Allow 500 page submissions without Turnstile (degraded state)
  def skip_turnstile?
    params[:turnstile_token].blank? && feedback_params[:page_type] == "500"
  end
end
```

- [ ] **Step 5: Run tests**

Run: `DISABLE_SPRING=1 bin/rails test test/controllers/api/error_feedbacks_controller_test.rb`
Expected: All 5 tests pass

- [ ] **Step 7: Run full test suite**

Run: `DISABLE_SPRING=1 bin/rails test`
Expected: All tests pass (268 existing + new tests)

- [ ] **Step 8: Commit**

```bash
git add app/controllers/api/error_feedbacks_controller.rb test/controllers/api/error_feedbacks_controller_test.rb config/routes.rb
git commit -m "Add API endpoint for error feedback submissions"
```

---

### Task 4: ErrorsController (404 & 422 pages)

**Files:**
- Create: `app/controllers/errors_controller.rb`
- Create: `app/views/errors/not_found.html.erb`
- Create: `app/views/errors/unprocessable.html.erb`
- Create: `app/views/errors/_feedback_form.html.erb`
- Create: `test/controllers/errors_controller_test.rb`
- Modify: `config/routes.rb`
- Modify: `config/application.rb`

- [ ] **Step 1: Write the controller test**

```ruby
# test/controllers/errors_controller_test.rb
require 'test_helper'

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "404 renders not found page" do
    get "/404"
    assert_response :not_found
    assert_select "h1", /404/
    assert_select "textarea" # feedback form
  end

  test "422 renders unprocessable page" do
    get "/422"
    assert_response :unprocessable_entity
    assert_select "h1", /422/
    assert_select "textarea" # feedback form
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `DISABLE_SPRING=1 bin/rails test test/controllers/errors_controller_test.rb`
Expected: Error — route/controller not found

- [ ] **Step 3: Add error routes and configure exceptions_app**

Edit `config/routes.rb` — add before the closing `end`:

```ruby
  # Custom error pages
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable", via: :all
```

Edit `config/application.rb` — add inside the `class Application` block:

```ruby
    # Route errors to ErrorsController instead of static pages
    config.exceptions_app = self.routes
```

- [ ] **Step 4: Create ErrorsController**

```ruby
# app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :push_gon

  def not_found
    render status: :not_found
  end

  def unprocessable
    render status: :unprocessable_entity
  end
end
```

- [ ] **Step 5: Create the shared feedback form partial**

This partial is used by both 404 and 422 pages. It includes the Turnstile widget and submits via JS to the API endpoint.

```erb
<%# app/views/errors/_feedback_form.html.erb %>
<div id="error-feedback" class="mt-5">
  <h5 class="text-center" style="text-transform: none; margin-top: 1rem;">Let us know what happened</h5>

  <form id="feedback-form" onsubmit="return submitFeedback(event)">
    <div class="form-group">
      <textarea id="feedback-message" class="form-control" rows="3" placeholder="What were you trying to do?" required></textarea>
    </div>
    <div class="form-group">
      <input id="feedback-email" type="email" class="form-control" placeholder="Your email (optional, if you'd like a follow-up)">
    </div>
    <div id="turnstile-widget" class="mb-3"></div>
    <button type="submit" class="btn btn-primary btn-block" id="feedback-submit">Send Feedback</button>
  </form>

  <div id="feedback-success" class="alert alert-success text-center" style="display: none;">
    Thanks for reporting this! We've been alerted and are looking into it.
  </div>

  <div id="feedback-error" class="alert alert-warning text-center" style="display: none;">
  </div>
</div>

<% turnstile_site_key = ENV['TURNSTILE_SITE_KEY'] %>
<% if turnstile_site_key.present? %>
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit" async defer></script>
<% end %>

<script>
  var turnstileToken = null;
  var turnstileSiteKey = '<%= turnstile_site_key %>';

  document.addEventListener('DOMContentLoaded', function() {
    if (turnstileSiteKey && typeof turnstile !== 'undefined') {
      turnstile.render('#turnstile-widget', {
        sitekey: turnstileSiteKey,
        callback: function(token) { turnstileToken = token; }
      });
    }
  });

  function submitFeedback(e) {
    e.preventDefault();
    var btn = document.getElementById('feedback-submit');
    btn.disabled = true;
    btn.textContent = 'Sending...';

    var body = {
      error_feedback: {
        page_type: '<%= page_type %>',
        message: document.getElementById('feedback-message').value,
        email: document.getElementById('feedback-email').value,
        url: window.location.href
      }
    };
    if (turnstileToken) body.turnstile_token = turnstileToken;

    fetch('/api/error_feedbacks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).then(function(r) {
      if (r.ok) {
        document.getElementById('feedback-form').style.display = 'none';
        document.getElementById('feedback-success').style.display = 'block';
      } else {
        throw new Error('Failed');
      }
    }).catch(function() {
      document.getElementById('feedback-error').textContent = 'Something went wrong sending your feedback. Please try again.';
      document.getElementById('feedback-error').style.display = 'block';
      btn.disabled = false;
      btn.textContent = 'Send Feedback';
    });

    return false;
  }
</script>
```

- [ ] **Step 6: Create 404 page**

```erb
<%# app/views/errors/not_found.html.erb %>
<div class="text-center mt-4 mb-4">
  <h1>404 &mdash; Page Not Found</h1>
  <p class="mt-3" style="font-size: 1.1rem;">
    The page you're looking for doesn't exist or may have been moved.
  </p>
  <a href="/" class="btn btn-primary mt-3">Back to the bakery</a>
</div>

<%= render "errors/feedback_form", page_type: "404" %>
```

- [ ] **Step 7: Create 422 page**

```erb
<%# app/views/errors/unprocessable.html.erb %>
<div class="text-center mt-4 mb-4">
  <h1>422 &mdash; Unprocessable Request</h1>
  <p class="mt-3" style="font-size: 1.1rem;">
    Your request couldn't be processed. This can happen if a form expired or a link is outdated.
  </p>
  <a href="/" class="btn btn-primary mt-3">Back to the bakery</a>
</div>

<%= render "errors/feedback_form", page_type: "422" %>
```

- [ ] **Step 8: Run tests**

Run: `DISABLE_SPRING=1 bin/rails test test/controllers/errors_controller_test.rb`
Expected: Both tests pass

- [ ] **Step 9: Run full test suite**

Run: `DISABLE_SPRING=1 bin/rails test`
Expected: All tests pass. Some existing tests may need adjustment if they relied on default error handling — check and fix.

- [ ] **Step 10: Commit**

```bash
git add app/controllers/errors_controller.rb app/views/errors/ test/controllers/errors_controller_test.rb config/routes.rb config/application.rb
git commit -m "Add controller-rendered 404 and 422 error pages with feedback form"
```

---

### Task 5: Static 500 Page

**Files:**
- Replace: `public/500.html`

No tests for static HTML — this is manually verified.

- [ ] **Step 1: Create the static 500 page**

Replace `public/500.html` with a fully self-contained HTML page that:
- Uses Google Fonts CDN for Raleway and Oswald
- Inline CSS matching the Motzi theme (cream background `#FFECD6`, purple `#352C63`, rust `#D5482C`, text `#2E2927`)
- Logo from the asset pipeline (hardcode the production URL or use a data-uri)
- Feedback form with Turnstile widget
- JS `fetch()` to `POST /api/error_feedbacks`
- Success message: "The site sent an email to the admin; we'll look into it soon."
- Failure message: humorous fallback with mailto link
- Turnstile graceful degradation: if widget doesn't load after 5s, allow submission without token

Key design notes:
- The page must be fully self-contained (no Rails helpers, no asset pipeline)
- Use the same form layout and fields as the controller-rendered pages
- Read `TURNSTILE_SITE_KEY` — since this is static HTML, the site key must be baked in at deploy time OR the form should work without it
- Since we can't use ERB in static HTML, the Turnstile site key should be read from a meta tag or hardcoded. For now, include the Turnstile script and widget div — if Turnstile isn't configured, the form still works (500 pages skip Turnstile verification server-side).

```html
<!DOCTYPE html>
<html>
<head>
  <title>500 — Internal Server Error</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Ctext y='.9em' font-size='90'%3E🍞%3C/text%3E%3C/svg%3E">
  <link href="https://fonts.googleapis.com/css2?family=Raleway:wght@300;500;700&family=Oswald:wght@400&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: #FFECD6;
      font-family: 'Raleway', sans-serif;
      font-weight: 300;
      color: #2E2927;
      min-height: 100vh;
      display: flex;
      justify-content: center;
      padding-top: 80px;
    }
    .container {
      background: white;
      box-shadow: 0 1px 4px 0 rgba(0,0,0,0.37);
      max-width: 640px;
      width: 100%;
      padding: 49px;
      margin-bottom: 100px;
    }
    @media (max-width: 420px) {
      .container { padding: 20px 10px; }
      body { padding-top: 40px; }
    }
    .logo-wrapper { text-align: center; margin-bottom: 2rem; }
    .logo-wrapper img { height: 100px; }
    h1 {
      font-family: 'Raleway', sans-serif;
      color: #352C63;
      text-align: center;
      font-weight: 500;
      font-size: 1.8rem;
      margin-bottom: 1rem;
    }
    p { text-align: center; font-size: 1.1rem; line-height: 1.6; margin-bottom: 1rem; }
    .back-link {
      display: block;
      text-align: center;
      margin: 1.5rem 0;
      font-family: 'Oswald', sans-serif;
      font-weight: 400;
      text-transform: uppercase;
      letter-spacing: 0.05rem;
      background: #352C63;
      color: white;
      padding: 10px 24px;
      text-decoration: none;
      border-radius: 2px;
      font-size: 0.9rem;
    }
    .back-link:hover { opacity: 0.9; }
    h5 {
      font-family: 'Raleway', sans-serif;
      color: #352C63;
      text-align: center;
      font-weight: 300;
      font-size: 1.1rem;
      margin: 2.5rem 0 1rem 0;
    }
    .divider { border: none; border-top: 2px solid #D5482C; margin: 2rem 0; }
    textarea, input[type="email"] {
      width: 100%;
      padding: 10px 14px;
      font-family: 'Raleway', sans-serif;
      font-size: 1rem;
      font-weight: 300;
      border: 1px solid #ccc;
      border-radius: 4px;
      margin-bottom: 12px;
    }
    textarea { min-height: 80px; resize: vertical; }
    textarea:focus, input[type="email"]:focus { outline: none; border-color: #352C63; }
    .submit-btn {
      width: 100%;
      font-family: 'Oswald', sans-serif;
      font-weight: 400;
      text-transform: uppercase;
      letter-spacing: 0.05rem;
      background: #352C63;
      color: white;
      padding: 12px;
      border: none;
      border-radius: 2px;
      font-size: 0.9rem;
      cursor: pointer;
    }
    .submit-btn:hover { opacity: 0.9; }
    .submit-btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .alert { padding: 12px 16px; border-radius: 4px; text-align: center; margin-top: 12px; display: none; }
    .alert-success { background: #d4edda; color: #155724; }
    .alert-warning { background: #fff3cd; color: #856404; }
    .alert-warning a { color: #856404; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo-wrapper">
      <a href="/"><img src="/assets/motzi-logo.png" alt="Motzi" onerror="this.style.display='none'"></a>
    </div>

    <h1>500 &mdash; Internal Server Error</h1>
    <p>Something went wrong on our end. We've been notified and are looking into it.</p>
    <a href="/" class="back-link">Back to the bakery</a>

    <hr class="divider">

    <h5>Let us know what happened</h5>

    <form id="feedback-form" onsubmit="return submitFeedback(event)">
      <textarea id="feedback-message" placeholder="What were you trying to do?" required></textarea>
      <input id="feedback-email" type="email" placeholder="Your email (optional, if you'd like a follow-up)">
      <button type="submit" class="submit-btn" id="feedback-submit">Send Feedback</button>
    </form>

    <div id="feedback-success" class="alert alert-success">
      The site sent an email to the admin; we'll look into it soon.
    </div>

    <div id="feedback-error" class="alert alert-warning">
    </div>
  </div>

  <script>
    // 500 page skips Turnstile entirely — server-side allows 500 submissions without token.
    // This page is shown when the app is broken, so we keep dependencies minimal.

    function submitFeedback(e) {
      e.preventDefault();
      var btn = document.getElementById('feedback-submit');
      btn.disabled = true;
      btn.textContent = 'Sending...';

      var body = {
        error_feedback: {
          page_type: '500',
          message: document.getElementById('feedback-message').value,
          email: document.getElementById('feedback-email').value,
          url: window.location.href
        }
      };
      // No turnstile_token — server allows 500 submissions without it

      fetch('/api/error_feedbacks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
      }).then(function(r) {
        if (r.ok) {
          document.getElementById('feedback-form').style.display = 'none';
          document.getElementById('feedback-success').style.display = 'block';
        } else {
          throw new Error('Failed');
        }
      }).catch(function() {
        var errorEl = document.getElementById('feedback-error');
        errorEl.innerHTML = 'Well... even the feedback form is broken. That\'s impressively bad. ' +
          'Try emailing us instead at <a href="mailto:motzi@motzi.org">motzi@motzi.org</a>.';
        errorEl.style.display = 'block';
        btn.disabled = false;
        btn.textContent = 'Send Feedback';
      });

      return false;
    }
  </script>
</body>
</html>
```

Notes:
- The logo `src="/assets/motzi-logo.png"` uses the public asset path. In production with asset pipeline, this may need to be the digested path. The `onerror` handler gracefully hides it if the path doesn't resolve. Check what the actual production asset URL is and adjust if needed — may need to use the undigested path or copy the logo to `public/`.
- The mailto link hardcodes `motzi@motzi.org` — verify this matches `ShopConfig.shop.email_reply_to` (config is in `config/shop.yml` which may be gitignored). Update if different.

- [ ] **Step 2: Verify the page renders correctly**

Open in browser: `http://localhost:3000/500.html` (direct static file access)
Verify: Motzi branding, cream background, purple headings, form fields, submit button

- [ ] **Step 3: Commit**

```bash
git add public/500.html
git commit -m "Replace default 500 page with branded static page and feedback form"
```

---

### Task 6: ActiveAdmin Resource

**Files:**
- Create: `app/admin/error_feedbacks.rb`

- [ ] **Step 1: Create ActiveAdmin resource**

```ruby
# app/admin/error_feedbacks.rb
ActiveAdmin.register ErrorFeedback do
  menu priority: 13, label: "Error Feedback"
  actions :index, :show, :destroy

  filter :page_type, as: :select, collection: %w[404 422 500]
  filter :email
  filter :created_at

  index do
    selectable_column
    id_column
    column :page_type
    column :message do |f|
      truncate(f.message, length: 80)
    end
    column :email
    column :url do |f|
      truncate(f.url, length: 50) if f.url
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :page_type
      row :message
      row :email do |f|
        link_to(f.email, "mailto:#{f.email}") if f.email.present?
      end
      row :url
      row :user_agent
      row :created_at
    end
  end
end
```

- [ ] **Step 2: Verify in browser**

Run: `DISABLE_SPRING=1 bin/rails server` (in worktree)
Visit: `http://localhost:3000/dev/login_as_admin` then `http://localhost:3000/admin/error_feedbacks`
Verify: Page loads with empty table, filters work

- [ ] **Step 3: Commit**

```bash
git add app/admin/error_feedbacks.rb
git commit -m "Add ErrorFeedback to ActiveAdmin"
```

---

### Task 7: Final Integration Test & Cleanup

- [ ] **Step 1: Run full test suite**

Run: `DISABLE_SPRING=1 bin/rails test`
Expected: All tests pass (existing + new)

- [ ] **Step 2: Run bun tests**

Run: `bun test`
Expected: All JS tests pass (no changes to JS tests expected)

- [ ] **Step 3: Fix any failing tests**

If `config.exceptions_app = self.routes` causes existing tests to hit the ErrorsController instead of raising, some tests may need adjustment. Common fix: tests that expect a raw 404 response may now get the full HTML page — assertions on response code should still pass, but assertions on body content may need updating.

- [ ] **Step 4: Manual smoke test**

Visit these URLs in development:
- `http://localhost:3000/nonexistent-page` — should show branded 404
- `http://localhost:3000/404` — should show branded 404
- `http://localhost:3000/422` — should show branded 422
- `http://localhost:3000/500.html` — should show branded 500 (static)
- Submit feedback on each page — check letter_opener for email
- Check `http://localhost:3000/admin/error_feedbacks` for stored records

- [ ] **Step 5: Commit any fixes**

```bash
git add -A
git commit -m "Fix test adjustments for custom error page routing"
```
