# Follow-up Plan for tabs & reminders

## 1. Progress so far
- Reminder jobs now group overlapping pickup days, keep the weekly menu primary, and pass both menus/items into the mailer so the HTML/text templates can render each menu’s deadline, notes, and order items in a single email.  
- Haven’t-ordered reminders similarly list every pending menu in one email while respecting `menu.messages` so subscribers still get only one reminder per deadline window.  
- Valentine fixture data + tests now cover the overlapping weekend/special scenario to ensure the new reminder behavior stays stable.  
- The ordering UI tabs only show when multiple menus are open, and the special menu is surfaced with a badge and pickup note so customers immediately see there is a secondary menu and when it picks up.

## 2. Outstanding work
1. Reminder visuals / logging follow-up  
   - Confirm both HTML and text versions render nicely in a mail preview (LetterOpener or similar) now that specials print with their notes, and tweak the copy if anything looks off.  
   - Double-check Sidekiq/Admin comments to ensure each menu reminder still logs its activity and that Ahoy messages carry the right `pickup_day`.

## 3. Future considerations
- The new reminder strategy still relies on `Setting.menu_id`/`Menu.current` when no explicit `menu_id` is provided, so the admin workflow for marking a “current” weekly batch remains unchanged.  
- After spiffing up the UI/reminder previews, revisit any admin reminders or mailer previews that still hardcode `Menu.current` to make sure special menus can surface in those contexts when needed.
