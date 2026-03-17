# Holiday Menus in Admin: What-to-Bake, Pickup Lists, Dashboard

## Problem

Holiday menus (e.g., Passover) have pickup days that overlap with regular weekly menus. Bakers need:
- The dashboard to show both regular and holiday bake counts, order stats, and sales
- A single pickup list per date that combines orders from all menus
- Menu show pages to continue showing only their own orders

## Fixtures: Same-Week Scenario

Add a regular menu for week `26w15` (same week as `passover_2026`) with pickup days on Apr 10-11, menu items, and orders so both menus coexist.

- `menus.yml`: `week_26w15` regular menu
- `pickup_days.yml`: `w26w15_fri`, `w26w15_sat` on Apr 10-11
- `menu_items.yml`: classic + rye on week_26w15
- `menu_item_pickup_days.yml`: wire to both days
- `orders.yml`: kyle orders from week_26w15; ljf already orders from passover_2026
- `order_items.yml`: items for both menus on overlapping dates

## New Route: `/admin/pickup_lists/:date`

ActiveAdmin custom page replacing the old `/admin/pickup_days/:id` show page.

- Takes a date string param (e.g., `2026-04-10`)
- Finds all `PickupDay` records whose `pickup_at` falls on that calendar date
- Aggregates orders across all pickup days on that date
- Two tabs: orders list (sorted by last name) and by-item view
- Items grouped or labeled by menu name so bakers can distinguish regular from holiday

## Dashboard Updates (`bakery.rb`)

- **What-to-bake**: Render for `Menu.current`, then also for `Menu.current_holiday` if present
- **Orders panel**: Add holiday order stats when `current_holiday` exists
- **Sales panel**: Also render sales for `current_holiday`
- All "Pickup List" links point to `/admin/pickup_lists/:date`

## Menu Show Page

- No changes to `_what_to_bake` logic (each menu shows its own orders)
- "Pickup List" links update to point to `/admin/pickup_lists/:date`

## Remove Old Pickup Day Show

- Delete the show block from `app/admin/pickup_day.rb`
- The ActiveAdmin resource remains for CRUD (creating/editing pickup days)

## Tests

- Pickup list: date with only regular orders; date with both regular + holiday
- Dashboard: renders both regular and holiday what-to-bake, orders, sales
- Menu show: existing tests still pass
