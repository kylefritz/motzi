# Menu strategy notes

## What changed from the old "current menu" flow

- Historically `Setting.menu_id` tracked which single menu deserved the "current" badge. `Menu.current` simply fetched that ID, `Menu.make_current!` wrote to the setting, and the API surface exposed an `isCurrent` flag for the UI to know which menu was being shown.
- Ordering, reminders, and most admin scopes were wired to `Menu.current` and therefore implicitly to `Setting.menu_id`. The UI always asked for `/menu.json`, and the backend assumed one menu was active at a time.
- That flow broke when we needed overlapping menus (holiday specials plus the weekly menu) because the single setting could only point to one menu.

## What the new flow does differently

- We still fall back to `Menu.current`/`Setting.menu_id` when no specific `menu_id` is requested, but the API now also returns every menu that is open for ordering via `Menu.open_for_ordering` so the client can render tabs.
- The UI toggles between open menus by passing `menu_id` to `/menus/:id.json` and rerendering the order form while continuing to respect ordering windows, reminder suppression for special menus, etc.
- We removed the `is_current` flag from the payload because the client no longer needs it; instead it relies on which tab is active and the `menu_id` returned by the endpoint.

## Remaining vestiges of the old strategy to consider

1. `Setting.menu_id` is still the source of truth for the weekly "current" menu. `Menu.current`, `Menu.make_current!`, and the admin scopes/filters around "current menu" still rely on it, so whatever happens with special menus they do not update this setting.
2. `Order.for_current_menu` and mailer previews still use `Menu.current`. The automated reminder jobs (`SendDayOf...`, `SendHaventOrdered...`) have been updated to query by pickup/deadline time to support overlapping menus, so they are no longer strictly tied to `Setting.menu_id`.
3. Admin interfaces (`app/admin/menus.rb`, `app/admin/orders.rb`, `app/admin/emails.rb`) still expose scopes filtered by `Setting.menu_id`. They may want to be revisited later if the admin should manage special menus differently.
4. Fixtures and tests that call `Menu.current` or rely on `Setting.menu_id` (orders, jobs, mailer previews) have to stay synchronized with whichever menu is marked current in the fixture data; they continue to exercise the old path, so keep that in mind when editing those files.
5. The `Setting` model still stores other unrelated knobs (reminder hours, shop info, etc.), but the only setting tied to the old current-menu process is `menu_id`. If we ever retire `Menu.make_current!`, remove the scopes, and stop referencing `Menu.current`, that is the last setting we can delete without affecting the UI.
