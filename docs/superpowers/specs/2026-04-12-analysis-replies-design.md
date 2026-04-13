# Analysis Replies via Email

## Goal

Let Kyle (and eventually other admins) reply to the weekly Motzi Activity Report email and have those replies:
1. Stored as `AnalysisReply` records attached to the relevant `AnomalyAnalysis`
2. Fed into next week's analysis prompt alongside the prior analysis they replied to

So Kyle can tell Claude things like "R14 isn't an error, stop flagging it" or "David Rodwin confirmed the duplicate" and have that context persist into future reports.

## Architecture

```
┌───────────┐                            ┌──────────────────┐
│  Motzi    │  ──── sends email ────▶   │  Kyle's inbox    │
│  Heroku   │       (Reply-To:          │                  │
│           │        reply+analysis-    └────────┬─────────┘
└─────▲─────┘         123@thepuff.co)            │
      │                                          │ replies
      │ POST /reply_ingress                      ▼
      │ (with secret)           ┌────────────────────────────┐
      │                         │ Cloudflare Email Worker    │
      └──────────────────────── │ on thepuff.co              │
                                │  - Verify SPF/DKIM         │
                                │  - Extract analysis_id     │
                                │  - POST parsed reply       │
                                │  - Bounce if rejected      │
                                └────────────────────────────┘
```

## Components

### 1. `AnalysisReply` model

```ruby
class AnalysisReply < ApplicationRecord
  belongs_to :anomaly_analysis
  belongs_to :user, optional: true

  validates :body, :author_email, presence: true
  validates :message_id, uniqueness: true, allow_nil: true

  enum :source, { email: 0, admin: 1 }
end
```

Schema:
- `anomaly_analysis_id` (FK, indexed)
- `user_id` (FK nullable — matched by email if sender is a User)
- `author_email` (string, not null — canonical identity for email replies)
- `author_name` (string — display name if parsed from From header)
- `body` (text)
- `message_id` (string, unique, nullable — RFC 5322 Message-ID for dedup)
- `source` (integer enum — `email` for inbound, `admin` for web UI)
- `created_at`, `updated_at`

### 2. `AnomalyAnalysis` gets `has_many :replies`

```ruby
has_many :replies, -> { order(:created_at) }, class_name: "AnalysisReply", dependent: :destroy
```

### 3. `AnomalyMailer` sets `Reply-To`

Current:
```ruby
mail(to: User.kyle.email_list, subject: "...")
```

New:
```ruby
mail(
  to: User.kyle.email_list,
  reply_to: "reply+analysis-#{@analysis.id}@thepuff.co",
  subject: "..."
)
```

### 4. Cloudflare Email Worker (`reply-ingress.js`)

Lives in a separate repo/directory — deployed to Cloudflare via `wrangler`. Pseudocode:

```javascript
export default {
  async email(message, env, ctx) {
    // 1. Verify SPF/DKIM via Authentication-Results header
    const authResults = message.headers.get("Authentication-Results") || "";
    if (!authResults.includes("spf=pass") || !authResults.includes("dkim=pass")) {
      await message.setReject("SPF or DKIM failed");
      return;
    }

    // 2. Extract analysis_id from recipient (reply+analysis-{id}@thepuff.co)
    const match = message.to.match(/reply\+analysis-(\d+)@/);
    if (!match) {
      await message.setReject("Unknown recipient");
      return;
    }
    const analysisId = match[1];

    // 3. Parse email body — extract reply text, strip quoted history
    const parsed = await parseEmail(message); // uses postal-mime or similar

    // 4. POST to Motzi
    const response = await fetch(`${env.MOTZI_URL}/reply_ingress`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${env.REPLY_WEBHOOK_SECRET}`
      },
      body: JSON.stringify({
        analysis_id: analysisId,
        from_email: parsed.from.address,
        from_name: parsed.from.name,
        body: parsed.text, // or stripped plaintext
        message_id: parsed.messageId,
        subject: parsed.subject
      })
    });

    if (!response.ok) {
      const { error } = await response.json();
      await message.setReject(error || "Rejected by Motzi");
    }
  }
}
```

Worker env vars: `MOTZI_URL`, `REPLY_WEBHOOK_SECRET`.

### 5. `ReplyIngressController`

```ruby
class ReplyIngressController < ActionController::API
  before_action :authenticate!

  def create
    analysis = AnomalyAnalysis.find_by(id: params[:analysis_id])
    return render json: { error: "Unknown analysis" }, status: :not_found unless analysis

    author_email = params[:from_email]&.downcase
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
    # Message-ID already processed — idempotent success
    render json: { status: "duplicate" }, status: :ok
  end

  private

  def authenticate!
    token = request.headers["Authorization"]&.sub(/^Bearer /, "")
    unless ActiveSupport::SecurityUtils.secure_compare(token.to_s, ENV["REPLY_WEBHOOK_SECRET"].to_s)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def strip_quoted(body)
    # Remove quoted reply history — match "On ... wrote:" lines and below
    body.to_s.split(/\n(On .+ wrote:|>.*|-+Original Message-+)/).first.to_s.strip
  end
end
```

Route: `post "/reply_ingress" => "reply_ingress#create"` (outside the normal auth middleware).

### 6. `AnomalyDetector` prompt changes

In `build_user_message`, where prior analyses are included:

```ruby
prior_analyses.each do |a|
  parts << ""
  parts << "### #{a.week_id} — #{a.created_at.strftime('%-m/%-d/%Y')} (#{a.trigger})"
  parts << a.result

  if a.replies.any?
    parts << ""
    parts << "**Operator replies:**"
    a.replies.each do |r|
      parts << "- #{r.author_name || r.author_email} (#{r.created_at.strftime('%-m/%-d')}): #{r.body}"
    end
  end
end
```

### 7. Admin UI

Show replies in the ActiveAdmin Activity Feed page — a panel under each analysis showing replies with author, date, and body. No reply-from-web UI in v1 (email only).

## Data Flow

1. Weekly: `AnalyzeAnomaliesJob` runs, creates `AnomalyAnalysis`, `AnomalyMailer` sends report with `Reply-To: reply+analysis-#{id}@thepuff.co`.
2. Kyle replies in Gmail. Email goes to Cloudflare routing for `thepuff.co`.
3. Email Worker receives the message, verifies SPF/DKIM, extracts `analysis_id`, POSTs parsed reply to Motzi.
4. `ReplyIngressController` authenticates via shared secret, checks sender is admin, creates `AnalysisReply`.
5. If any step rejects, Worker calls `message.setReject(reason)` — Cloudflare generates a standard bounce back to the sender.
6. Next week: `AnomalyDetector` includes replies inline with each prior analysis in the prompt.

## Security

- **Authentication**: Worker → Motzi uses a shared `REPLY_WEBHOOK_SECRET` (env var on both sides).
- **Spoofing protection**: Worker rejects any email where SPF or DKIM doesn't pass.
- **Authorization**: Motzi only accepts replies from admin users (`is_admin: true`).
- **Dedup**: `message_id` is unique — replaying the same email is a no-op.
- **Rate limiting**: Relying on Cloudflare's infrastructure; not adding app-level throttling for v1.

## Testing

- **Model**: `AnalysisReplyTest` for validations, uniqueness on message_id, enum.
- **Controller**: `ReplyIngressControllerTest` covers:
  - Happy path creates reply
  - Missing/wrong auth returns 401
  - Non-admin sender returns 403
  - Unknown analysis returns 404
  - Duplicate message_id returns 200 (idempotent)
  - Body stripping removes quoted history
- **Mailer**: `AnomalyMailerTest` asserts `Reply-To` header includes `analysis-{id}`.
- **Integration**: `AnomalyDetector` spec with replies present shows them in the built prompt.
- **Worker**: manual test after deploy — send a real reply and verify round-trip. No JS test suite for v1.

## Open items (not in scope for v1)

- Web UI to reply without email
- Replies on other record types (orders, menus) — extract `Replyable` concern if/when needed
- Bounces back to invalid senders include a human-readable explanation (Cloudflare's default bounce may or may not include the reject reason — verify after deploy)
- Inline attachments in replies (ignored for v1)

## Config / deploy checklist

- [ ] Add `REPLY_WEBHOOK_SECRET` to Heroku env (generated via `SecureRandom.hex(32)`)
- [ ] Create Cloudflare Email Worker in thepuff.co account, set env vars
- [ ] Configure Cloudflare Email Routing rule: `reply+*@thepuff.co` → Worker
- [ ] Verify SPF/DKIM pass for Gmail-originated replies
- [ ] Smoke test: reply to an analysis, confirm reply appears in admin
