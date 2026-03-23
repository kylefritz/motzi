# Generalize Feedback System — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename ErrorFeedback → Feedback, generalize beyond error pages, add inline feedback form to the React menu UI. Closes #313.

**Architecture:** Migration renames table/column, then all references are updated (model, controller, mailer, admin, views, tests, static 500 page). A new React `FeedbackForm` component is added to Menu.tsx.

**Tech Stack:** Rails 7.2, React 18, TypeScript, Bootstrap 4, MJML, Minitest

**Spec:** `docs/superpowers/specs/2026-03-23-generalize-feedback-design.md`

**Working directory:** `/Users/kyle/code/motzi/.worktrees/custom-error-pages`

---

### Task 1: Migration — Rename table and column

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_rename_error_feedbacks_to_feedbacks.rb`

- [ ] **Step 1: Create the migration**

Run: `DISABLE_SPRING=1 bin/rails generate migration RenameErrorFeedbacksToFeedbacks`

Edit the generated migration:

```ruby
class RenameErrorFeedbacksToFeedbacks < ActiveRecord::Migration[7.2]
  def change
    rename_table :error_feedbacks, :feedbacks
    rename_column :feedbacks, :page_type, :source
  end
end
```

- [ ] **Step 2: Run migration**

Run: `DISABLE_SPRING=1 bin/rails db:migrate`

- [ ] **Step 3: Commit**

```bash
git add db/migrate/*_rename_error_feedbacks_to_feedbacks.rb db/schema.rb
git commit -m "Rename error_feedbacks table to feedbacks, page_type to source"
```

---

### Task 2: Rename model, mailer, and admin

**Files:**
- Create: `app/models/feedback.rb` (replaces `app/models/error_feedback.rb`)
- Create: `app/mailers/feedback_mailer.rb` (replaces `app/mailers/error_feedback_mailer.rb`)
- Create: `app/views/feedback_mailer/feedback_received.mjml` (replaces `app/views/error_feedback_mailer/`)
- Create: `app/views/feedback_mailer/feedback_received.text.erb`
- Create: `app/admin/feedbacks.rb` (replaces `app/admin/error_feedbacks.rb`)
- Delete: `app/models/error_feedback.rb`, `app/mailers/error_feedback_mailer.rb`, `app/views/error_feedback_mailer/`, `app/admin/error_feedbacks.rb`
- Create: `test/models/feedback_test.rb` (replaces `test/models/error_feedback_test.rb`)
- Create: `test/mailers/feedback_mailer_test.rb` (replaces `test/mailers/error_feedback_mailer_test.rb`)
- Delete: `test/models/error_feedback_test.rb`, `test/mailers/error_feedback_mailer_test.rb`

- [ ] **Step 1: Create Feedback model**

```ruby
# app/models/feedback.rb
class Feedback < ApplicationRecord
  validates :source, presence: true, inclusion: { in: %w[404 422 500 menu general] }
  validates :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
```

- [ ] **Step 2: Create FeedbackMailer**

```ruby
# app/mailers/feedback_mailer.rb
class FeedbackMailer < ApplicationMailer
  def feedback_received
    @feedback = params[:feedback]
    mail(to: User.kyle.email_list,
         subject: "Feedback from #{@feedback.source}") do |format|
      format.text
      format.mjml
    end
  end
end
```

- [ ] **Step 3: Create mailer templates**

Copy from `app/views/error_feedback_mailer/` to `app/views/feedback_mailer/`, replacing all `@feedback.page_type` with `@feedback.source` and updating the header text from "Error Feedback" to "Feedback" and "Page Report" to "Report".

MJML template (`app/views/feedback_mailer/feedback_received.mjml`):

```erb
<mjml>
  <mj-head>
    <%= render partial: "shared_mailer/head", formats: [:html] %>
  </mj-head>
  <mj-body background-color="#FFECD6" width="1200px">
    <%= render partial: "shared_mailer/header", formats: [:html] %>

    <mj-section background-color="#ffffff" padding="32px 40px 24px 40px">
      <mj-column>
        <mj-text padding="0 0 8px 0" font-size="13px" font-weight="500" letter-spacing="0.08em" text-transform="uppercase" color="#D5482C">
          Feedback
        </mj-text>

        <mj-text padding="0 0 20px 0" font-size="26px" font-weight="700" line-height="1.3" color="#352C63">
          <%= @feedback.source %> Report
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
          <strong>Source:</strong> <%= @feedback.source %>
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

Text template (`app/views/feedback_mailer/feedback_received.text.erb`):

```erb
Feedback: <%= @feedback.source %>
<%= "=" * 40 %>

<%= @feedback.message %>

<% if @feedback.email.present? %>
Reply to: <%= @feedback.email %>
<% end %>
---
Source: <%= @feedback.source %>
<% if @feedback.url.present? %>URL: <%= @feedback.url %><% end %>
Submitted: <%= @feedback.created_at.strftime("%Y-%m-%d %l:%M%P %Z") %>
<% if @feedback.user_agent.present? %>Browser: <%= @feedback.user_agent %><% end %>
```

- [ ] **Step 4: Create admin resource**

```ruby
# app/admin/feedbacks.rb
ActiveAdmin.register Feedback do
  menu priority: 10, label: "Feedback"
  actions :index, :show, :destroy

  filter :source, as: :select, collection: %w[404 422 500 menu general]
  filter :email
  filter :created_at

  index do
    selectable_column
    id_column
    column :source
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
      row :source
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

- [ ] **Step 5: Delete old files**

```bash
rm app/models/error_feedback.rb
rm app/mailers/error_feedback_mailer.rb
rm -rf app/views/error_feedback_mailer
rm app/admin/error_feedbacks.rb
```

- [ ] **Step 6: Create tests**

Model test (`test/models/feedback_test.rb`):

```ruby
require 'test_helper'

class FeedbackTest < ActiveSupport::TestCase
  test "valid with source and message" do
    feedback = Feedback.new(source: "menu", message: "Great bread!")
    assert feedback.valid?
  end

  test "invalid without source" do
    feedback = Feedback.new(message: "test")
    assert_not feedback.valid?
  end

  test "invalid without message" do
    feedback = Feedback.new(source: "menu")
    assert_not feedback.valid?
  end

  test "invalid with unknown source" do
    feedback = Feedback.new(source: "unknown", message: "test")
    assert_not feedback.valid?
  end

  test "valid sources" do
    %w[404 422 500 menu general].each do |s|
      feedback = Feedback.new(source: s, message: "test")
      assert feedback.valid?, "#{s} should be valid"
    end
  end

  test "email format validation" do
    feedback = Feedback.new(source: "menu", message: "test", email: "not-an-email")
    assert_not feedback.valid?

    feedback.email = "user@example.com"
    assert feedback.valid?
  end

  test "email is optional" do
    feedback = Feedback.new(source: "menu", message: "test")
    assert feedback.valid?
  end
end
```

Mailer test (`test/mailers/feedback_mailer_test.rb`):

```ruby
require 'test_helper'

class FeedbackMailerTest < ActionMailer::TestCase
  test "feedback_received" do
    feedback = Feedback.create!(
      source: "menu",
      message: "The sourdough was amazing!",
      email: "customer@example.com",
      url: "/menu",
      user_agent: "Mozilla/5.0"
    )

    email = FeedbackMailer.with(feedback: feedback).feedback_received

    assert_emails 1 do
      email.deliver_now
    end

    assert_includes email.to, users(:kyle).email
    assert_equal "Feedback from menu", email.subject

    text = email.text_part.body.to_s
    assert_includes text, "menu"
    assert_includes text, "The sourdough was amazing!"
    assert_includes text, "customer@example.com"

    html = email.html_part.body.to_s
    assert_includes html, "Feedback"
    assert_includes html, "menu"
    assert_includes html, "sourdough"
  end

  test "feedback_received from error page" do
    feedback = Feedback.create!(
      source: "404",
      message: "Page missing"
    )

    email = FeedbackMailer.with(feedback: feedback).feedback_received

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal "Feedback from 404", email.subject
  end
end
```

- [ ] **Step 7: Delete old tests**

```bash
rm test/models/error_feedback_test.rb
rm test/mailers/error_feedback_mailer_test.rb
```

- [ ] **Step 8: Run tests**

Run: `DISABLE_SPRING=1 bin/rails test test/models/feedback_test.rb test/mailers/feedback_mailer_test.rb`
Expected: All tests pass

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "Rename ErrorFeedback to Feedback across model, mailer, admin, and tests"
```

---

### Task 3: Rename API controller and update routes

**Files:**
- Create: `app/controllers/api/feedbacks_controller.rb` (replaces `error_feedbacks_controller.rb`)
- Delete: `app/controllers/api/error_feedbacks_controller.rb`
- Edit: `config/routes.rb`
- Create: `test/controllers/api/feedbacks_controller_test.rb` (replaces `error_feedbacks_controller_test.rb`)
- Delete: `test/controllers/api/error_feedbacks_controller_test.rb`

- [ ] **Step 1: Create renamed controller**

```ruby
# app/controllers/api/feedbacks_controller.rb
class Api::FeedbacksController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    unless skip_turnstile? || verify_turnstile
      return render json: { error: "Verification failed" }, status: :forbidden
    end

    feedback = Feedback.new(feedback_params)
    feedback.user_agent = request.user_agent

    if feedback.save
      FeedbackMailer.with(feedback: feedback).feedback_received.deliver_now
      render json: { success: true }, status: :created
    else
      render json: { error: feedback.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:source, :message, :email, :url)
  end

  def verify_turnstile
    token = params[:turnstile_token]
    return false if token.blank?

    secret = ENV["TURNSTILE_SECRET_KEY"]
    return true if secret.blank?

    response = Net::HTTP.post_form(
      URI("https://challenges.cloudflare.com/turnstile/v0/siteverify"),
      { secret: secret, response: token }
    )
    JSON.parse(response.body)["success"] == true
  rescue StandardError
    false
  end

  def skip_turnstile?
    params[:turnstile_token].blank? && feedback_params[:source] == "500"
  end
end
```

- [ ] **Step 2: Update routes**

In `config/routes.rb`, replace:
```ruby
  namespace :api do
    resources :error_feedbacks, only: [:create]
  end
```
with:
```ruby
  namespace :api do
    resources :feedbacks, only: [:create]
  end
```

- [ ] **Step 3: Delete old controller**

```bash
rm app/controllers/api/error_feedbacks_controller.rb
```

- [ ] **Step 4: Create renamed test**

```ruby
# test/controllers/api/feedbacks_controller_test.rb
require 'test_helper'
require 'webmock/minitest'

class Api::FeedbacksControllerTest < ActionDispatch::IntegrationTest
  TURNSTILE_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  setup do
    @original_turnstile_key = ENV["TURNSTILE_SECRET_KEY"]
    ENV["TURNSTILE_SECRET_KEY"] = "test-secret"
  end

  teardown do
    ENV["TURNSTILE_SECRET_KEY"] = @original_turnstile_key
  end

  test "creates feedback and sends email" do
    stub_turnstile(success: true)

    assert_difference 'Feedback.count', 1 do
      assert_emails 1 do
        post api_feedbacks_path, params: {
          feedback: {
            source: "menu",
            message: "Great bread!",
            email: "customer@example.com",
            url: "/menu"
          },
          turnstile_token: "valid-token"
        }, as: :json
      end
    end

    assert_response :created
    feedback = Feedback.last
    assert_equal "menu", feedback.source
    assert_equal "Great bread!", feedback.message
  end

  test "returns 422 with invalid params" do
    stub_turnstile(success: true)

    assert_no_difference 'Feedback.count' do
      post api_feedbacks_path, params: {
        feedback: { source: "menu", message: "" },
        turnstile_token: "valid-token"
      }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "returns 403 with invalid turnstile token" do
    stub_turnstile(success: false)

    assert_no_difference 'Feedback.count' do
      post api_feedbacks_path, params: {
        feedback: { source: "menu", message: "test" },
        turnstile_token: "invalid"
      }, as: :json
    end

    assert_response :forbidden
  end

  test "skips turnstile for 500 source without token" do
    assert_difference 'Feedback.count', 1 do
      post api_feedbacks_path, params: {
        feedback: { source: "500", message: "Everything broke" }
      }, as: :json
    end

    assert_response :created
  end

  test "captures user agent" do
    stub_turnstile(success: true)

    post api_feedbacks_path,
      params: {
        feedback: { source: "menu", message: "test" },
        turnstile_token: "valid-token"
      },
      headers: { "User-Agent" => "TestBrowser/1.0" },
      as: :json

    assert_response :created
    assert_equal "TestBrowser/1.0", Feedback.last.user_agent
  end

  private

  def stub_turnstile(success:)
    stub_request(:post, TURNSTILE_URL)
      .to_return(body: { success: success }.to_json, headers: { "Content-Type" => "application/json" })
  end
end
```

- [ ] **Step 5: Delete old test**

```bash
rm test/controllers/api/error_feedbacks_controller_test.rb
```

- [ ] **Step 6: Run tests**

Run: `DISABLE_SPRING=1 bin/rails test test/controllers/api/feedbacks_controller_test.rb`
Expected: All 5 tests pass

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Rename API endpoint from error_feedbacks to feedbacks"
```

---

### Task 4: Update error pages and static 500

**Files:**
- Edit: `app/views/errors/_feedback_form.html.erb` — change API path and field name
- Edit: `public/500.html` — change API path and field name

- [ ] **Step 1: Update feedback form partial**

In `app/views/errors/_feedback_form.html.erb`, make these changes:
- Change `page_type: '<%= page_type %>'` → `source: '<%= page_type %>'`
- Change `fetch('/api/error_feedbacks'` → `fetch('/api/feedbacks'`
- Change the request body key from `error_feedback` → `feedback`

The `page_type` local variable name stays the same (it's just the ERB variable passed from the view) — only the JSON payload field changes.

- [ ] **Step 2: Update static 500 page**

In `public/500.html`, make these changes:
- Change `page_type: '500'` → `source: '500'`
- Change `fetch('/api/error_feedbacks'` → `fetch('/api/feedbacks'`
- Change `error_feedback:` → `feedback:` in the request body

- [ ] **Step 3: Run full test suite**

Run: `DISABLE_SPRING=1 bin/rails test`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add app/views/errors/_feedback_form.html.erb public/500.html
git commit -m "Update error pages to use renamed feedback API"
```

---

### Task 5: React FeedbackForm component

**Files:**
- Create: `app/javascript/packs/menu/FeedbackForm.tsx`
- Edit: `app/javascript/packs/menu/Menu.tsx`

- [ ] **Step 1: Create FeedbackForm component**

```tsx
// app/javascript/packs/menu/FeedbackForm.tsx
import React, { useState } from "react";

type FeedbackFormState = "link" | "form" | "success" | "error";

export default function FeedbackForm() {
  const [state, setState] = useState<FeedbackFormState>("link");
  const [message, setMessage] = useState("");
  const [email, setEmail] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);

    try {
      const response = await fetch("/api/feedbacks", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          feedback: {
            source: "menu",
            message,
            email: email || undefined,
            url: window.location.href,
          },
        }),
      });

      if (response.ok) {
        setState("success");
      } else {
        setState("error");
      }
    } catch {
      setState("error");
    } finally {
      setSubmitting(false);
    }
  };

  if (state === "link") {
    return (
      <div className="text-center mt-2 mb-3">
        <small>
          <a
            href="#"
            onClick={(e) => {
              e.preventDefault();
              setState("form");
            }}
          >
            Share feedback
          </a>
        </small>
      </div>
    );
  }

  if (state === "success") {
    return (
      <div className="alert alert-success text-center mt-2 mb-3">
        Thanks for the feedback!
      </div>
    );
  }

  if (state === "error") {
    return (
      <div className="alert alert-warning text-center mt-2 mb-3">
        Something went wrong.{" "}
        <a
          href="#"
          onClick={(e) => {
            e.preventDefault();
            setState("form");
          }}
        >
          Try again
        </a>
      </div>
    );
  }

  return (
    <div className="mt-2 mb-3">
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <textarea
            className="form-control"
            rows={3}
            placeholder="What's on your mind?"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            required
          />
        </div>
        <div className="form-group">
          <input
            type="email"
            className="form-control"
            placeholder="Your email (optional)"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </div>
        <button
          type="submit"
          className="btn btn-primary btn-block"
          disabled={submitting}
        >
          {submitting ? "Sending..." : "Send Feedback"}
        </button>
        <div className="text-center mt-1">
          <small>
            <a
              href="#"
              onClick={(e) => {
                e.preventDefault();
                setState("link");
                setMessage("");
                setEmail("");
              }}
            >
              Cancel
            </a>
          </small>
        </div>
      </form>
    </div>
  );
}
```

- [ ] **Step 2: Add FeedbackForm to Menu.tsx**

In `app/javascript/packs/menu/Menu.tsx`:

Add import at the top:
```tsx
import FeedbackForm from "./FeedbackForm";
```

Add `<FeedbackForm />` after the submit button div (after line 129, before `</>`):
```tsx
      <FeedbackForm />
    </>
```

- [ ] **Step 3: Run bun tests**

Run: `bun test`
Expected: All JS tests pass (FeedbackForm is self-contained, no test changes needed)

- [ ] **Step 4: Run full Rails test suite**

Run: `DISABLE_SPRING=1 bin/rails test`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add app/javascript/packs/menu/FeedbackForm.tsx app/javascript/packs/menu/Menu.tsx
git commit -m "Add inline feedback form to menu UI

Closes #313"
```

---

### Task 6: Final integration test

- [ ] **Step 1: Run full test suites**

Run: `DISABLE_SPRING=1 bin/rails test && bun test`
Expected: All tests pass

- [ ] **Step 2: Manual smoke test**

- Visit `/menu` — verify "Share feedback" link appears below submit button
- Click it — verify inline form expands
- Submit feedback — verify success message, check letter_opener for email
- Visit `/404`, `/422`, `/500` — verify error pages still work with renamed API
- Visit `/admin/feedbacks` — verify admin shows all submissions

- [ ] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "Final integration fixes for generalized feedback"
```
