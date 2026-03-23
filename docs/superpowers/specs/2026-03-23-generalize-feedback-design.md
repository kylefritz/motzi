# Generalize Feedback System

## Summary

Rename `ErrorFeedback` to `Feedback` and generalize it beyond error pages. Add an inline feedback form to the React menu/ordering UI so members can share feedback from anywhere, not just error pages. Closes #313.

## Database

Rename table `error_feedbacks` → `feedbacks`, rename column `page_type` → `source`.

| Column | Type | Notes |
|--------|------|-------|
| `source` | string, not null | "404", "422", "500", "menu", "general" |
| `message` | text, not null | User's feedback |
| `email` | string, nullable | Optional contact email |
| `url` | string, nullable | Page URL where feedback was submitted |
| `user_agent` | string, nullable | Browser info |
| `created_at` | datetime | |

## Model

`ErrorFeedback` → `Feedback`

- Validates `source` presence + inclusion in `%w[404 422 500 menu general]`
- Validates `message` presence
- Validates `email` format if present

## API

`POST /api/error_feedbacks` → `POST /api/feedbacks`

- Request body: `{ feedback: { source, message, email, url }, turnstile_token }`
- Same Turnstile verification logic (skip for source "500")
- Same `deliver_now` for resilience
- Returns 201/422/403

## Mailer

`ErrorFeedbackMailer` → `FeedbackMailer`

- Subject: `"Feedback from [source]"` (e.g. "Feedback from menu", "Feedback from 404")
- Same MJML template with `source` replacing `page_type`
- Sent to `User.kyle.email_list`

## Admin

`ActiveAdmin.register Feedback` replaces `ErrorFeedback`

- Menu priority 10, label "Feedback" — appears before the advanced items (Spam, Visits, Versions)
- Filter on `source` instead of `page_type`
- Same index/show layout

## Error Pages

Update all references:
- `ErrorsController` views: `_feedback_form.html.erb` posts to `/api/feedbacks` with `source` instead of `page_type`
- `public/500.html`: JS posts to `/api/feedbacks` with `source: "500"`

## React: Menu Feedback Link

Add a "Share feedback" text link below the main purple CTA button in the menu view. When clicked:
- Expands an inline form: textarea ("What's on your mind?") + optional email + submit button
- Posts to `POST /api/feedbacks` with `source: "menu"` and `url: window.location.href`
- On success: hide form, show "Thanks for the feedback!"
- On error: show error message
- No Turnstile on this form (user is already authenticated on the menu page)

## Routing

```ruby
namespace :api do
  resources :feedbacks, only: [:create]
end
```

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `db/migrate/..._rename_error_feedbacks_to_feedbacks.rb` | Create | Rename table + column |
| `app/models/feedback.rb` | Create (replaces error_feedback.rb) | Renamed model |
| `app/models/error_feedback.rb` | Delete | Replaced by feedback.rb |
| `app/controllers/api/feedbacks_controller.rb` | Create (replaces error_feedbacks_controller.rb) | Renamed controller |
| `app/controllers/api/error_feedbacks_controller.rb` | Delete | Replaced |
| `app/mailers/feedback_mailer.rb` | Create (replaces error_feedback_mailer.rb) | Renamed mailer |
| `app/mailers/error_feedback_mailer.rb` | Delete | Replaced |
| `app/views/feedback_mailer/` | Create (replaces error_feedback_mailer/) | Renamed templates |
| `app/views/error_feedback_mailer/` | Delete | Replaced |
| `app/admin/feedbacks.rb` | Create (replaces error_feedbacks.rb) | Renamed admin |
| `app/admin/error_feedbacks.rb` | Delete | Replaced |
| `app/views/errors/_feedback_form.html.erb` | Edit | Update API path + field name |
| `public/500.html` | Edit | Update API path + field name |
| `config/routes.rb` | Edit | Rename namespace route |
| `app/javascript/packs/menu/Menu.tsx` | Edit | Add feedback link + inline form |
| `test/models/feedback_test.rb` | Create (replaces error_feedback_test.rb) | Renamed tests |
| `test/controllers/api/feedbacks_controller_test.rb` | Create | Renamed + new tests |
| `test/mailers/feedback_mailer_test.rb` | Create | Renamed tests |
