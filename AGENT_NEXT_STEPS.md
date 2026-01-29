# Next Steps (agent)

## Summary plan

- Adopt `_special` suffix strategy for `week_id` with one special + one regular per base week.
- Rename `allow_overlap` to `is_special` in code (rename existing migration; never went live) and add `allow_overlap` alias for compatibility.
- Add `base_week_id` helper and normalize `week_id` before validation so `is_special` adds/removes suffix and enforces uniqueness at the base week level.
- Update comparisons/date math to use `base_week_id` (e.g. `can_publish?`, `for_current_week_id?`, `from_week_id`, credit item scopes, etc.).
- Audit `Menu.current` call sites and decide per usage: single menu vs. both menus vs. merged facade.
- Keep reminder emails **disabled** for special menus.

## Testing reminders

- Run `bundle exec rails test` and `bun run test` as you work (targeted files first, full suites when stable).
