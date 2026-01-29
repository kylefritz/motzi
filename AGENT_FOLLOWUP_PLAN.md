# Follow-up Plan for tabs & reminders

## 1. Progress so far
- Reminder jobs now group overlapping pickup days, keep the weekly menu primary, and pass both menus/items into the mailer so the HTML/text templates can render each menu’s deadline, notes, and order items in a single email.  
- Haven’t-ordered reminders similarly list every pending menu in one email while respecting `menu.messages` so subscribers still get only one reminder per deadline window.  
- Valentine fixture data + tests now cover the overlapping weekend/special scenario to ensure the new reminder behavior stays stable.

## 2. Outstanding work
1. Ordering UI: keep the weekly menu primary and visually highlight the special  
   - The client already receives `openMenus` and renders tabs when more than one is available, but we still need to polish this so the weekly menu loads first, the special tab carries a badge/note to call out pickup timing (use the menu note or `menu_pickup_summary`), and any tab navigation clearly conveys the pickup window (e.g., show the note near the tab and/or a headline above the tabs when a special is active).  
   - Ensure the primary tab matches `render_current_order`’s primary selection logic and that switching tabs reloads the matching `menu_id` payload for its ordering windows.
2. Reminder visuals / logging follow-up  
   - Confirm both HTML and text versions render nicely in a mail preview (LetterOpener or similar), then revisit copy/formatting if needed so specials and weekly menus look distinct but cohesive.  
   - Double-check Sidekiq/Admin logs to confirm we still add comments per menu and that the `pickup_day` tracked for Ahoy records reflects the advisory menu. 

## 3. Future considerations
- The new reminder strategy continues relying on `Setting.menu_id`/`Menu.current` when no explicit `menu_id` is provided, so the admin workflow for marking a “current” weekly batch still works without touching overlap logic.  
- Once the UI polish is complete, we should revisit the admin reminders and any mailer previews that still hardcode `Menu.current` to ensure they surface special menus when appropriate.  
