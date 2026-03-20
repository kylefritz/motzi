# Security Review: Sensitive Data in Public Repo

## Summary of Findings

### CRITICAL: Hardcoded password hash in seeds (db/seeds.rb:42)

```ruby
encrypted_password: '$2a$11$yjTtvz3CIZ29DrS0WcXgueq6durSyPy.pBeDmslhwa26H0hHuoi3u'
```

The comment on line 35 says "uses the same password as production." This means
anyone can brute-force this bcrypt hash offline to recover the **production admin
password**. Bcrypt is slow but not uncrackable — especially if the password is
short or common. This is the single most dangerous item in the repo.

**Remediation:**
1. **Immediately rotate the production admin password** (it may already be compromised).
2. Replace the hardcoded hash with a generated random password:
   ```ruby
   password: SecureRandom.hex(16)
   ```
3. Use `bfg-repo-cleaner` or `git filter-repo` to purge the hash from history.

---

### HIGH: Stripe test publishable key (app.json:23)

```
pk_test_uAmNwPrPVkEoywEZYTE66AnV00mGp7H2Ud
```

While publishable keys are *designed* to be public, a **test** key lets anyone
create test charges against your Stripe account, potentially causing confusion.
More importantly, it reveals your Stripe account identity.

**Remediation:** Replace with `"required": true` or a placeholder. Move to env var.

---

### MEDIUM: Personal email addresses (multiple files)

| Email | Files |
|-------|-------|
| `kyle.p.fritz@gmail.com` | user.rb:63, seeds.rb:36/38, fixtures/users.yml:10, mockMenuJson.ts:130, user_test.rb:94 |
| `meghan.l.ames@gmail.com` | fixtures/users.yml:11, user_test.rb:94 |
| `adrian.alday@gmail.com` | fixtures/users.yml:20 |
| `laura.flamm@gmail.com` | fixtures/users.yml:29, user_test.rb:93 |
| `mayapamela@gmail.com` | user.rb:65 |
| `trimmer.russell@gmail.com` | user.rb:69 |
| `jess@gmail.com` | fixtures/users.yml:54, user_test.rb:95 |
| `motzi.bread@gmail.com` | config/shop.yml:6 |

Your call on which of these you consider sensitive. The personal Gmail addresses
of non-owner friends/members (Adrian, Laura, Meghan) are the most concerning —
they didn't sign up to have their emails in a public repo.

**Remediation:**
- **Fixtures/tests:** Replace with `@example.com` addresses (RFC 2606 reserved domain).
- **user.rb constants (MAYA_EMAIL, RUSSELL_EMAIL, User.kyle):** Move to Rails credentials
  or env vars. These are used at runtime to identify business owners.
- **config/shop.yml:** Move `email_reply_to` to env var or Rails credentials.
- **seeds.rb:** Use env var for admin email.

---

### LOW: Real names in fixtures

Names like "Adrian Alday", "Laura Flamm" are in test fixtures. Less sensitive
than emails but still PII of real people. Consider replacing with fictional names.

---

### LOW: Phone number in fixtures (users.yml:14)

`555-123-4567` — this is a fictional 555 number, so it's fine.

---

## What's Already Secure (Good!)

- `config/master.key` — gitignored
- `config/credentials.yml.enc` — properly encrypted (this IS meant to be committed)
- `.env` — gitignored
- All real API secrets (Stripe secret, AWS, SendGrid) — env vars only
- `.devcontainer/` uses placeholder values

---

## Remediation Plan

### Phase 1: Fix the code (this PR)

1. **db/seeds.rb** — Replace hardcoded bcrypt hash with `SecureRandom.hex(16)`.
   Remove hardcoded email, use `ENV.fetch('REVIEW_APP_ADMIN_EMAIL', 'admin@example.com')`.

2. **app.json** — Replace Stripe test key with `"required": true`.

3. **test/fixtures/users.yml** — Replace all real emails with `@example.com`.
   Replace real names with fictional ones.

4. **test/models/user_test.rb** — Update email assertions to match new fixtures.

5. **test/javascript/menu/mockMenuJson.ts** — Replace email with `@example.com`.

6. **app/models/user.rb** — Move `User.kyle`, `MAYA_EMAIL`, `RUSSELL_EMAIL` to
   use `Rails.application.credentials` or env vars.

7. **config/shop.yml** — Move `email_reply_to` to env var with fallback.

### Phase 2: Rewrite git history

After the code changes are merged, use **BFG Repo-Cleaner** or **git filter-repo**
to scrub the old values from all historical commits:

```bash
# Install git-filter-repo (pip install git-filter-repo)

# Create a file with expressions to replace
cat > replacements.txt << 'EOF'
kyle.p.fritz@gmail.com==>kyle@example.com
meghan.l.ames@gmail.com==>meghan@example.com
adrian.alday@gmail.com==>adrian@example.com
laura.flamm@gmail.com==>laura@example.com
mayapamela@gmail.com==>maya@example.com
trimmer.russell@gmail.com==>russell@example.com
$2a$11$yjTtvz3CIZ29DrS0WcXgueq6durSyPy.pBeDmslhwa26H0hHuoi3u==>REDACTED_HASH
pk_test_uAmNwPrPVkEoywEZYTE66AnV00mGp7H2Ud==>pk_test_PLACEHOLDER
EOF

# Run the replacement
git filter-repo --replace-text replacements.txt
```

Then force-push all branches. All collaborators will need to re-clone.

### Phase 3: Post-cleanup

1. **Rotate the production admin password** immediately.
2. **Rotate the Stripe test publishable key** in the Stripe dashboard.
3. Verify no GitHub forks retain the old history (you can't control this — another
   reason to rotate credentials).
