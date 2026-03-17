# Holiday Menus: What-to-Bake, Pickup Lists, Dashboard — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Holiday menus appear alongside regular menus in the dashboard (what-to-bake, orders, sales) and a new date-based pickup list aggregates orders across all menus for a given day.

**Architecture:** Replace the ID-based `/admin/pickup_days/:id` show page with a date-based `/admin/pickup_lists/:date` custom page. Update the dashboard to render what-to-bake/orders/sales for both `Menu.current` and `Menu.current_holiday`. Menu show pages stay unchanged (own orders only). Links everywhere point to the new date-based route.

**Tech Stack:** Rails 6.1, ActiveAdmin (Arbre views), minitest fixtures

---

## Task 1: Fixtures — Same-Week Regular + Holiday Scenario

Set up test data where a regular menu and the Passover holiday menu share the same week (26w15) with pickup days on the same dates (Apr 10-11, 2026).

**Files:**
- Modify: `test/fixtures/menus.yml`
- Modify: `test/fixtures/pickup_days.yml`
- Modify: `test/fixtures/menu_items.yml`
- Modify: `test/fixtures/menu_item_pickup_days.yml`
- Modify: `test/fixtures/orders.yml`
- Modify: `test/fixtures/order_items.yml`

**Step 1: Add the regular menu for week 26w15**

In `test/fixtures/menus.yml`, add:

```yaml
week_26w15:
  name: week_26w15
  week_id: 26w15
  subscriber_note: |
    Regular bread this week!
```

**Step 2: Add pickup days for week_26w15 on the same dates as Passover**

In `test/fixtures/pickup_days.yml`, add:

```yaml
# week 26w15 (same dates as passover)
w26w15_fri:
  menu: week_26w15
  order_deadline_at: <%= Time.zone.parse("2026-04-08 22:00") %>
  pickup_at:         <%= Time.zone.parse("2026-04-10 15:00") %>

w26w15_sat:
  menu: week_26w15
  order_deadline_at: <%= Time.zone.parse("2026-04-09 22:00") %>
  pickup_at:         <%= Time.zone.parse("2026-04-11 08:00") %>
```

**Step 3: Add menu items (classic + rye) for week_26w15**

In `test/fixtures/menu_items.yml`, add:

```yaml
#
# week 26w15
#
w26w15_classic:
  <<: *default
  menu: week_26w15
  item: classic

w26w15_rye:
  <<: *default
  menu: week_26w15
  item: rye
```

**Step 4: Wire menu items to both pickup days**

In `test/fixtures/menu_item_pickup_days.yml`, add:

```yaml
# week 26w15
w26w15_classic_fri:
  menu_item: w26w15_classic
  pickup_day: w26w15_fri

w26w15_classic_sat:
  menu_item: w26w15_classic
  pickup_day: w26w15_sat

w26w15_rye_fri:
  menu_item: w26w15_rye
  pickup_day: w26w15_fri

w26w15_rye_sat:
  menu_item: w26w15_rye
  pickup_day: w26w15_sat
```

**Step 5: Add orders — kyle orders regular, ljf already orders passover**

In `test/fixtures/orders.yml`, add:

```yaml
kyle_week_26w15:
  user: kyle
  menu: week_26w15
  comments: regular bread please

kyle_passover:
  user: kyle
  menu: passover_2026
  comments: passover treats too
```

**Step 6: Add order items for both menus on overlapping dates**

In `test/fixtures/order_items.yml`, add:

```yaml
# week 26w15 regular orders (kyle)
k_w26_classic_fri:
  order: kyle_week_26w15
  item: classic
  pickup_day: w26w15_fri

k_w26_rye_fri:
  order: kyle_week_26w15
  item: rye
  pickup_day: w26w15_fri

# passover orders (kyle)
k_passover_almond_fri:
  order: kyle_passover
  item: almond_cake
  pickup_day: passover_fri

# ljf already has ljf_passover order — add order items
ljf_passover_toffee_fri:
  order: ljf_passover
  item: matzo_toffee
  pickup_day: passover_fri

ljf_passover_almond_sat:
  order: ljf_passover
  item: almond_cake
  pickup_day: passover_sat
```

**Step 7: Run existing tests to make sure fixtures load**

Run: `bin/rails test test/controllers/admin/menu_controller_test.rb test/controllers/admin/dashboard_controller_test.rb test/controllers/admin/pickup_day_controller_test.rb`
Expected: All pass (existing tests use week1/week2 fixtures, not 26w15)

**Step 8: Commit**

```
git add test/fixtures/
git commit -m "Add fixtures: regular + holiday menus in same week for 26w15"
```

---

## Task 2: New Date-Based Pickup List Page

Create `/admin/pickup_lists/:date` that aggregates orders from all pickup days on a given calendar date.

**Files:**
- Create: `app/admin/pickup_list.rb`
- Modify: `app/admin/pickup_day.rb` (remove show block)

**Step 1: Write failing test for the new pickup list route**

Create `test/controllers/admin/pickup_list_controller_test.rb`:

```ruby
require 'test_helper'

class Admin::PickupListControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week_26w15).make_current!
    menus(:passover_2026).make_current!  # sets holiday_menu_id
    sign_in users(:kyle)
  end

  test "pickup list for date with only regular orders (week1)" do
    menus(:week1).make_current!
    get "/admin/pickup_lists/2019-01-03"
    assert_response :success

    assert_el_count 1, '#pickup-list'
    assert_el_count 2, '#pickup-list tbody tr', 'adrian and kyle have orders on Thu Jan 3'
  end

  test "pickup list for date with both regular and holiday orders" do
    get "/admin/pickup_lists/2026-04-10"
    assert_response :success

    assert_el_count 1, '#pickup-list'
    # kyle has regular (classic, rye) + holiday (almond cake), ljf has holiday (matzo toffee)
    assert_el_count 2, '#pickup-list tbody tr', 'kyle and ljf both have orders on Apr 10'
  end

  test "pickup list by-item tab shows items from both menus" do
    get "/admin/pickup_lists/2026-04-10"
    assert_response :success

    # 4 items: Classic, Rye (regular) + Almond Cake, Matzo Toffee (holiday)
    assert_el_count 4, '#by-item .column', 'classic, rye, almond cake, matzo toffee'
  end

  test "pickup list 404s for date with no pickup days" do
    get "/admin/pickup_lists/2099-01-01"
    assert_response :not_found
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/pickup_list_controller_test.rb`
Expected: FAIL (route doesn't exist)

**Step 3: Create the pickup list page**

Create `app/admin/pickup_list.rb`:

```ruby
ActiveAdmin.register_page "Pickup Lists" do
  menu false

  page_action :show, method: :get do
    date = Date.parse(params[:date])
    @pickup_days = PickupDay.unscoped
      .where("pickup_at::date = ?", date)
      .order(:pickup_at)
      .includes(menu: [], order_items: [:item, order: :user])

    if @pickup_days.empty?
      head :not_found
      return
    end

    @date = date

    # Aggregate all orders across all pickup days on this date
    orders_by_user = {}
    @pickup_days.each do |pickup_day|
      pickup_day.menu.orders.not_skip.includes(:user, order_items: :item).each do |order|
        order_items = order.order_items.select { |oi| oi.pickup_day_id == pickup_day.id }
        next if order_items.empty?

        orders_by_user[order.user] ||= []
        orders_by_user[order.user].concat(order_items)
      end
    end

    @rows = orders_by_user.map { |user, items| [user, items] }
      .sort_by { |user, _| user.sort_key }

    render 'admin/pickup_lists/show', layout: 'active_admin'
  end

  controller do
    def index
      redirect_to admin_root_path
    end
  end
end
```

**Step 4: Add the route**

In `config/routes.rb`, inside the `Rails.application.routes.draw` block, add before `ActiveAdmin.routes(self)`:

```ruby
# date-based pickup lists (must be before ActiveAdmin.routes)
authenticate :user, ->(user) { user.is_admin? } do
  get '/admin/pickup_lists/:date', to: 'admin/pickup_lists#show', as: :admin_pickup_list
end
```

Wait — ActiveAdmin custom pages use their own routing. Let's use a plain controller instead for cleaner date-based routing.

**Revised Step 3: Create a plain controller**

Create `app/controllers/admin/pickup_lists_controller.rb`:

```ruby
class Admin::PickupListsController < ActiveAdmin::BaseController
  def show
    date = Date.parse(params[:date])
    pickup_days = PickupDay.unscoped
      .where("pickup_at::date = ?", date)
      .order(:pickup_at)
      .includes(menu: {orders: [:user, {order_items: :item}]})

    if pickup_days.empty?
      head :not_found
      return
    end

    @date = date
    @pickup_days = pickup_days

    rows_hash = {}
    pickup_days.each do |pickup_day|
      pickup_day.menu.orders.not_skip.each do |order|
        order_items = order.order_items.select { |oi| oi.pickup_day_id == pickup_day.id }
        next if order_items.empty?
        rows_hash[order.user] ||= []
        rows_hash[order.user].concat(order_items)
      end
    end

    @rows = rows_hash.sort_by { |user, _| user.sort_key }
  end
end
```

**Revised Step 4: Add route**

In `config/routes.rb`, add inside the existing `authenticate :user` block (line 31-35):

```ruby
get '/admin/pickup_lists/:date', to: 'admin/pickup_lists#show', as: :admin_pickup_list
```

**Step 5: Create the view**

Create `app/views/admin/pickup_lists/show.html.arb`:

```ruby
Arbre::Context.new({}, self) do
  h2 "Pickup List — #{@date.strftime('%A %m/%d/%Y')}"

  @pickup_days.map(&:menu).uniq.each do |menu|
    para do
      text_node "Menu: "
      a menu.name, href: admin_menu_path(menu)
      if menu.holiday?
        status_tag 'Holiday', color: 'orange', style: 'margin-left: 6px'
      end
    end
  end

  tabs do
    tab :orders do
      table_for @rows, id: 'pickup-list' do
        column("Last Name") { |user, _| user.last_name.presence || user.email }
        column("First Name") { |user, _| user.first_name }
        column("Items") do |user, order_items|
          ul do
            order_items.group_by(&:item).each do |item, ois|
              qty = ois.sum(&:quantity)
              li "#{qty > 1 ? "#{qty}x " : ""}#{item.name}"
            end
          end
        end
        column("Sign") { "" }
      end
    end

    tab :by_item do
      columns do
        items_hash = {}
        @rows.each do |user, order_items|
          order_items.each do |oi|
            item_name = oi.item.name
            items_hash[item_name] ||= []
            items_hash[item_name].push([user, oi.quantity])
          end
        end

        items_hash.sort_by { |name, _| name }.each do |item_name, user_rows|
          users = Hash.new(0)
          user_rows.each { |user, qty| users[user.name.downcase] += qty }

          column id: "by-item" do
            h3 item_name
            ol do
              users.sort_by { |name, _| name }.each do |name, qty|
                li do
                  span name
                  strong("x#{qty}") if qty > 1
                end
              end
            end
          end
        end
      end
    end
  end
end
```

Note: The `.arb` extension may need to be `.html.erb` with Arbre rendering inline depending on how ActiveAdmin handles views for non-AA controllers. We may need to adjust this during implementation — check how `ActiveAdmin::BaseController` renders views. If it's simpler, we can use ERB + helpers instead. The test will tell us.

**Step 6: Remove old pickup_day show block**

In `app/admin/pickup_day.rb`, delete the entire `show do |pickup_day| ... end` block (lines 5-63), leaving only:

```ruby
ActiveAdmin.register PickupDay do
  permit_params :menu_id, :pickup_at, :order_deadline_at
  menu false
end
```

**Step 7: Run tests**

Run: `bin/rails test test/controllers/admin/pickup_list_controller_test.rb`
Expected: All 4 tests pass

**Step 8: Update old pickup day tests**

Rewrite `test/controllers/admin/pickup_day_controller_test.rb` to remove the show tests (they tested the old ID-based page). Keep it minimal or delete if nothing remains.

**Step 9: Run full test suite to check for breakage**

Run: `bin/rails test`
Expected: All pass

**Step 10: Commit**

```
git add app/admin/pickup_list.rb app/admin/pickup_day.rb app/controllers/admin/pickup_lists_controller.rb app/views/admin/pickup_lists/ config/routes.rb test/controllers/admin/pickup_list_controller_test.rb test/controllers/admin/pickup_day_controller_test.rb
git commit -m "Add date-based pickup list page, remove old pickup_day show"
```

---

## Task 3: Update What-to-Bake Links

Change "Pickup List" links in `_what_to_bake.html.arb` to point to `/admin/pickup_lists/:date` instead of `/admin/pickup_days/:id`.

**Files:**
- Modify: `app/views/admin/menus/_what_to_bake.html.arb`

**Step 1: Run existing dashboard test to confirm it passes before changes**

Run: `bin/rails test test/controllers/admin/dashboard_controller_test.rb`
Expected: Pass

**Step 2: Update the link**

In `app/views/admin/menus/_what_to_bake.html.arb`, change line 6:

```ruby
# Before:
a("Pickup List", href: admin_pickup_day_path(pickup_day))

# After:
a("Pickup List", href: admin_pickup_list_path(date: pickup_day.pickup_at.to_date))
```

**Step 3: Run tests**

Run: `bin/rails test test/controllers/admin/dashboard_controller_test.rb test/controllers/admin/menu_controller_test.rb`
Expected: Pass

**Step 4: Commit**

```
git add app/views/admin/menus/_what_to_bake.html.arb
git commit -m "Point what-to-bake pickup links to date-based pickup list"
```

---

## Task 4: Dashboard — Holiday What-to-Bake

Add holiday menu bake counts to the dashboard when a current holiday menu exists.

**Files:**
- Modify: `app/admin/bakery.rb`
- Modify: `test/controllers/admin/dashboard_controller_test.rb`

**Step 1: Write failing test**

Add to `test/controllers/admin/dashboard_controller_test.rb`:

```ruby
test "dashboard shows holiday what-to-bake when holiday menu is current" do
  menus(:week_26w15).make_current!
  menus(:passover_2026).make_current!  # sets holiday_menu_id

  get '/admin/dashboard'
  assert_response :success

  # Regular menu what-to-bake
  assert_el_count 1, '#what-to-bake-Fri'
  assert_el_count 1, '#what-to-bake-Sat'

  # Holiday menu what-to-bake
  assert_el_count 1, '#holiday-what-to-bake-Fri'
  assert_el_count 1, '#holiday-what-to-bake-Sat'
  # kyle: almond cake, ljf: matzo toffee on Friday
  assert_el_count 3, '#holiday-what-to-bake-Fri .breads tbody tr', 'almond cake + matzo toffee + total'
end

test "dashboard hides holiday section when no holiday menu" do
  menus(:week1).make_current!
  Setting.holiday_menu_id = nil

  get '/admin/dashboard'
  assert_response :success

  assert_select '#holiday-what-to-bake-Thu', count: 0
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/dashboard_controller_test.rb`
Expected: New tests fail

**Step 3: Add holiday what-to-bake to dashboard**

In `app/admin/bakery.rb`, after line 51 (`render 'admin/menus/what_to_bake', {menu: menu}`), add:

```ruby
holiday_menu = Menu.current_holiday
if holiday_menu
  panel "Holiday: #{holiday_menu.name}" do
    render 'admin/menus/what_to_bake', {menu: holiday_menu, id_prefix: 'holiday-'}
  end
end
```

**Step 4: Update `_what_to_bake.html.arb` to support an id_prefix**

In `app/views/admin/menus/_what_to_bake.html.arb`, update line 4 to use a configurable prefix:

```ruby
# Before:
column id: "what-to-bake-#{pickup_day.day_abbr}" do

# After:
prefix = local_assigns.fetch(:id_prefix, '')
column id: "#{prefix}what-to-bake-#{pickup_day.day_abbr}" do
```

Note: `local_assigns` is available in Arbre partials rendered with `render`. We need to verify this works — if not, pass via `{menu: menu, id_prefix: 'holiday-'}` as a local and access it differently.

**Step 5: Run tests**

Run: `bin/rails test test/controllers/admin/dashboard_controller_test.rb`
Expected: All pass

**Step 6: Commit**

```
git add app/admin/bakery.rb app/views/admin/menus/_what_to_bake.html.arb test/controllers/admin/dashboard_controller_test.rb
git commit -m "Show holiday what-to-bake on dashboard"
```

---

## Task 5: Dashboard — Holiday Orders + Sales Panels

Add holiday order stats and sales to the dashboard.

**Files:**
- Modify: `app/admin/bakery.rb`
- Modify: `test/controllers/admin/dashboard_controller_test.rb`

**Step 1: Write failing test**

Add to `test/controllers/admin/dashboard_controller_test.rb`:

```ruby
test "dashboard shows holiday orders and sales" do
  menus(:week_26w15).make_current!
  menus(:passover_2026).make_current!

  get '/admin/dashboard'
  assert_response :success

  # Holiday orders panel exists
  assert_select 'h3', text: /Holiday.*Orders/i
  # Holiday sales panel exists
  assert_select 'h3', text: /Holiday.*Sales/i
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/dashboard_controller_test.rb -n "/holiday orders/"`
Expected: FAIL

**Step 3: Add holiday orders panel to dashboard**

In `app/admin/bakery.rb`, after the existing "Orders" panel (after line 43), add:

```ruby
holiday_menu = Menu.current_holiday
if holiday_menu
  panel "Holiday Orders: #{holiday_menu.name}" do
    holiday_orders = Order.for_holiday_menu
    num_orders = holiday_orders.not_skip.count
    table_for [{type: "Holiday", ordered: num_orders, total: num_orders}], class: 'subscribers' do
      column :type
      column :ordered
      column(:total) { |h| strong(h[:total]) }
    end
  end
end
```

**Step 4: Add holiday sales panel**

After the existing "Sales" panel (after line 47), add:

```ruby
if holiday_menu
  panel "Holiday Sales: #{holiday_menu.name}" do
    render 'admin/menus/sales', {menu: holiday_menu}
  end
end
```

Note: `holiday_menu` is already defined from the orders section above. But since Arbre scoping can be tricky, we may need to re-fetch it. Check during implementation.

**Step 5: Run tests**

Run: `bin/rails test test/controllers/admin/dashboard_controller_test.rb`
Expected: All pass

**Step 6: Commit**

```
git add app/admin/bakery.rb test/controllers/admin/dashboard_controller_test.rb
git commit -m "Show holiday orders and sales on dashboard"
```

---

## Task 6: Final Cleanup + Full Test Run

**Step 1: Run full test suite**

Run: `bin/rails test`
Expected: All pass

**Step 2: Manual smoke test (optional)**

If running local dev, visit:
- `/admin/dashboard` — should show both regular and holiday panels
- `/admin/pickup_lists/2026-04-10` — should show combined orders
- `/admin/menus/:id` for a regular menu — should show only its own orders

**Step 3: Commit any remaining fixes, then done**
