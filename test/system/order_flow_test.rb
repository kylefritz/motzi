require "application_system_test_case"

# End-to-end: the compiled React bundle (app/assets/builds, built by
# `bun run build`) driving the real MenusController/OrdersController in
# headless Chrome. Also runs axe-core accessibility checks (#378 items 4, 12).
class OrderFlowTest < ApplicationSystemTestCase
  # assert_email_sent wraps perform_enqueued_jobs; system tests don't get it
  # by default. The test adapter is process-wide, so jobs enqueued by the
  # Puma thread serving the browser still run inline.
  include ActiveJob::TestHelper
  include StripeStubs

  AXE_SOURCE_PATH = Rails.root.join("node_modules/axe-core/axe.min.js")

  setup do
    menus(:week2).make_current!

    # The browser checks deadlines against its own clock (moment() in
    # Contexts.ts), and travel_to only fakes Ruby's clock, so time travel
    # would leave Chrome and Puma disagreeing about whether ordering is open.
    # Instead, move week2's pickup days into the real near future.
    now = Time.current
    pickup_days(:w2_d1_thurs).update!(order_deadline_at: now + 2.days, pickup_at: now + 4.days)
    pickup_days(:w2_d2_sat).update!(order_deadline_at: now + 4.days, pickup_at: now + 6.days)
  end

  test "subscriber orders from their menu link and gets a confirmation email" do
    member = users(:jess)
    classic = items(:classic)
    pickup_day = pickup_days(:w2_d1_thurs)

    visit "/menu?uid=#{member.hashid}"
    assert_selector "[data-testid='item-#{classic.id}']"
    assert_no_critical_accessibility_violations("subscriber menu")

    within "[data-testid='item-#{classic.id}']" do
      find("[data-testid='pickup-day-#{classic.id}-#{pickup_day.id}']").click
      find("[data-testid='add-to-cart-#{classic.id}']").click
      assert_text "Added to cart!"
    end
    find("textarea.form-control").fill_in with: "system test order"

    assert_email_sent do
      assert_ordered do
        click_button "Submit Order"
        assert_text(/we've got your order!/i) # heading is CSS uppercased
      end
    end

    order = member.orders.find_by!(menu: menus(:week2))
    assert_equal "system test order", order.comments
    assert_equal [ [ classic.id, pickup_day.id, 1 ] ],
                 order.order_items.map { |oi| [ oi.item_id, oi.pickup_day_id, oi.quantity ] }
    assert_nil order.stripe_charge_id

    email = ActionMailer::Base.deliveries.last
    assert_includes email.to, member.email
  end

  # Stripe Elements renders the card field in a cross-origin iframe from
  # js.stripe.com and tokenizes in the browser, which WebMock (server-side)
  # can't stub. So the card-charge path stays covered by
  # OrdersControllerTest; here we drive the guest checkout at a $0
  # pay-what-you-can price, which submits without a card.
  test "guest checks out from the marketplace at a pay-what-you-can price" do
    rye = items(:rye)
    pickup_day = pickup_days(:w2_d2_sat)

    visit "/menu"
    assert_selector "[data-testid='item-#{rye.id}']"

    within "[data-testid='item-#{rye.id}']" do
      find("[data-testid='pickup-day-#{rye.id}-#{pickup_day.id}']").click
      find("[data-testid='add-to-cart-#{rye.id}']").click
      assert_text "Added to cart!"
    end

    fill_in "First Name", with: "Guest"
    fill_in "Last Name", with: "Shopper"
    fill_in "Email", with: "guest.shopper@example.com"
    fill_in "Phone", with: "555-222-3333"
    find("input[aria-label='Price']").fill_in with: "0"

    assert_no_critical_accessibility_violations("marketplace checkout")

    assert_email_sent do
      assert_ordered do
        click_button "Submit Order"
        assert_text(/we've got your order!/i) # heading is CSS uppercased
      end
    end

    guest = User.find_by!(email: "guest.shopper@example.com")
    order = guest.orders.find_by!(menu: menus(:week2))
    assert_equal [ [ rye.id, pickup_day.id ] ], order.order_items.map { |oi| [ oi.item_id, oi.pickup_day_id ] }
    assert_equal 0, order.stripe_charge_amount
    assert_nil order.stripe_charge_id
    assert_not_requested :post, StripeStubs::STRIPE_CHARGES_URL
  end

  private

  # Injects axe-core (npm dev dependency) into the page and fails on any
  # violation with impact "critical". Serious/moderate issues are printed so
  # they stay visible without failing the build.
  def assert_no_critical_accessibility_violations(page_name)
    page.execute_script(AXE_SOURCE_PATH.read)
    violations = page.evaluate_async_script(<<~JS)
      const done = arguments[arguments.length - 1];
      axe.run(document, { resultTypes: ["violations"] })
        .then((results) => done(results.violations.map((v) => ({
          id: v.id, impact: v.impact, help: v.help,
          targets: v.nodes.map((n) => n.target.join(" ")).slice(0, 5)
        }))))
        .catch((error) => done([{ id: "axe-error", impact: "critical", help: String(error), targets: [] }]));
    JS

    summary = violations.map { |v| "#{v['impact']}: #{v['id']} (#{v['help']}) #{v['targets'].join(', ')}" }
    puts "\naxe #{page_name}:\n  #{summary.join("\n  ")}" if summary.any?

    critical = violations.select { |v| v["impact"] == "critical" }
    assert_empty critical, "critical accessibility violations on #{page_name}:\n#{summary.join("\n")}"
  end
end
