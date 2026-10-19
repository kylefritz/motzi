require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get "/admin/users"
    assert_response :success
  end

  test "get show" do
    obj = users(:kyle)
    get "/admin/users/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = users(:kyle)
    get "/admin/users/#{obj.id}/edit"
    assert_response :success
  end

  test "show lists orders newest first" do
    orders(:kyle_week1).update_columns(created_at: 3.days.ago)
    orders(:kyle_week2).update_columns(created_at: 1.day.ago)

    get "/admin/users/#{users(:kyle).id}"
    assert_response :success

    hrefs = admin_panel("Orders").css("a[href^='/admin/orders/']").map { |a| a["href"] }
    assert_operator hrefs.index("/admin/orders/#{orders(:kyle_week2).id}"), :<,
                    hrefs.index("/admin/orders/#{orders(:kyle_week1).id}")
  end

  test "show lists emails newest first" do
    user = users(:kyle)
    Ahoy::Message.create!(user: user, to: user.email, mailer: "MenuMailer#weekly_menu_email", subject: "Older email", sent_at: 3.days.ago)
    Ahoy::Message.create!(user: user, to: user.email, mailer: "MenuMailer#weekly_menu_email", subject: "Newer email", sent_at: 1.day.ago)

    get "/admin/users/#{user.id}"
    assert_response :success

    subjects = admin_panel("Emails").css("tbody td.col-subject").map { |td| td.text.strip }
    assert_operator subjects.index("Newer email"), :<, subjects.index("Older email")
  end

  test "show has a credit history newest first with a running balance" do
    credit_items(:kyle).update_columns(created_at: 30.days.ago)
    orders(:kyle_week1).update_columns(created_at: 20.days.ago)

    get "/admin/users/#{users(:kyle).id}"
    assert_response :success

    ledger_rows = admin_panel("Credits").css("table.credit-ledger tbody tr")
    rows = ledger_rows.map { |tr| tr.css("td").map { |td| td.text.strip } }
    assert_equal [ "+26", "26" ], rows.last[1, 2], "oldest row is the welcome credits"
    assert_equal [ "-1", "25" ], rows[-2][1, 2], "then the week1 order"
    assert_equal users(:kyle).credits.to_s, rows.first[2], "newest row ends at the current balance"

    week1_links = ledger_rows[-2].css("a").map { |a| a["href"] }
    assert_includes week1_links, "/admin/orders/#{orders(:kyle_week1).id}"
    assert_includes week1_links, "/admin/menus/#{menus(:week1).id}"
  end

  test "credit history says who recorded each change, and a deduction without a memo reads as removed" do
    user = users(:adrian)
    PaperTrail.request(whodunnit: users(:russell).id.to_s) { user.credit_items.create!(quantity: -2) }
    PaperTrail.request(whodunnit: user.id.to_s) { user.credit_items.create!(quantity: 6, memo: "6x credits") }

    get "/admin/users/#{user.id}"
    assert_response :success

    rows = admin_panel("Credits").css("table.credit-ledger tbody tr").map { |tr| tr.css("td").map { |td| td.text.strip } }
    assert_includes rows, rows.find { |r| r[1] == "-2" }
    removed = rows.find { |r| r[1] == "-2" }
    assert_equal "Credits removed", removed[3]
    assert_equal "Russell", removed[4]
    assert_equal "Customer", rows.find { |r| r[1] == "+6" }[4]
  end

  test "orders panel shows the credits each credit-paid order used" do
    get "/admin/users/#{users(:kyle).id}"
    assert_response :success

    panel = admin_panel("Orders")
    headers = panel.css("thead th").map { |th| th.text.strip }
    col = headers.index("Credits used")
    assert col, "Credits used column: #{headers.inspect}"
    row = panel.css("tbody tr").find { |tr| tr.css("a[href='/admin/orders/#{orders(:kyle_week1).id}']").any? }
    assert_equal orders(:kyle_week1).credits.to_s, row.css("td")[col].text.strip
  end

  test "user details summarize the account and drop breads per week" do
    get "/admin/users/#{users(:kyle).id}"
    assert_response :success

    details = admin_panel("User Details")
    assert_includes details.text, users(:kyle).credits.to_s
    assert_includes details.text, "Weekly menu"
    assert_match(/member since/i, details.text)
    assert_not_includes response.body, "Breads Per Week"
  end

  test "show caps the credit history at 20 entries with a link to the full history" do
    user = users(:adrian)
    25.times { |i| user.credit_items.create!(quantity: 1, memo: "top-up #{i}") }

    get "/admin/users/#{user.id}"
    assert_response :success
    assert_equal 20, admin_panel("Credits").css("table.credit-ledger tbody tr").size
    assert_select "a[href=?]", "/admin/users/#{user.id}?ledger=all", text: /all 2\d entries/

    get "/admin/users/#{user.id}?ledger=all"
    assert_response :success
    assert_operator admin_panel("Credits").css("table.credit-ledger tbody tr").size, :>=, 25
  end

  test "post resend email" do
    obj = users(:kyle)
    assert_email_sent do
      post "/admin/users/#{obj.id}/resend_menu"
    end
    assert_response :redirect
  end

  test "delete user with orders is blocked" do
    obj = users(:kyle)
    assert obj.orders.any?, "fixture user should have orders"

    assert_no_difference "User.count" do
      delete "/admin/users/#{obj.id}"
    end
    assert_redirected_to "/admin/users"
    follow_redirect!
    assert_select ".flash_alert", text: /without orders/
  end

  test "batch delete only removes users without orders" do
    deletable = User.create!(
      email: "deletable@example.com",
      first_name: "Delete",
      last_name: "Me",
      password: "password123"
    )
    keep = users(:kyle)
    assert keep.orders.any?, "fixture user should have orders"

    assert_difference "User.count", -1 do
      delete "/admin/users/batch_action", params: {
        collection_selection: [ deletable.id, keep.id ]
      }
    end

    assert_redirected_to "/admin/users"
    assert_nil User.find_by(id: deletable.id)
    assert User.exists?(keep.id)
  end

  private

  def admin_panel(title)
    css_select(".panel").find { |panel| panel.at_css("h3")&.text&.strip == title } ||
      flunk("no admin panel titled #{title.inspect}")
  end
end
