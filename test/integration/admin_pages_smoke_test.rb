require "test_helper"

# Renders every admin GET page, so a page that 500s (like the OpenStruct crash
# on /admin/activity_feed, error_events #2312) fails CI even if nobody wrote a
# dedicated test for it. New ActiveAdmin resources and pages are picked up
# automatically from the routes.
#
# Pages render with fixture data, and the ops tables (dyno metrics, uptime,
# error events...) have current-week fixtures (see test/support/fixture_helpers.rb),
# so dashboards render their populated branches. Index pages must not show
# ActiveAdmin's empty state, or the test only exercised the empty branch.
class AdminPagesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Routes that aren't pages, or need params we can't infer.
  SKIP = {
    "admin/activity_feed#prompt_preview" => "renders the LLM prompt; covered in activity_feed_controller_test",
    "admin/menus#menu_builder" => "React mount; covered in menu_controller_test"
  }.freeze

  # Index pages allowed to render ActiveAdmin's empty state.
  EMPTY_INDEX_OK = {}.freeze

  # Non-:id segments, keyed by segment name.
  PARAM_VALUES = {
    date: -> { PickupDay.first.pickup_at.to_date.to_s }
  }.freeze

  # Tables that are deliberately fixture-free (tests create rows inline). Filled
  # in with realistic associations so show pages render their populated parts.
  INLINE_RECORDS = {
    ContactMessage => -> { ContactMessage.create!(name: "Pat Baker", email: "pat@example.com", message: "Do you do wholesale?") },
    Ahoy::Visit => -> { Ahoy::Visit.create!(user: users(:kyle), started_at: Time.current, visit_token: "smoke-visit", visitor_token: "smoke-visitor", landing_page: "/menu") },
    Ahoy::Message => -> { Ahoy::Message.create!(user: users(:kyle), mailer: "ConfirmationMailer#order_email", subject: "Your order", to: users(:kyle).email, sent_at: Time.current, menu_id: menus(:week1).id) }
  }.freeze

  def self.admin_get_routes
    Rails.application.routes.routes.filter_map do |route|
      controller = route.defaults[:controller]
      next unless route.verb == "GET" && controller&.start_with?("admin/")

      path = route.path.spec.to_s.delete_suffix("(.:format)")
      [ "#{controller}##{route.defaults[:action]}", path ]
    end.uniq(&:first)
  end

  def setup
    menus(:week1).make_current!
    sign_in users(:kyle)
  end

  admin_get_routes.each do |key, path_template|
    next if SKIP.key?(key)

    test "GET #{path_template} (#{key}) renders" do
      path = build_path(key, path_template)
      seed_inline_record(key) if key.end_with?("#index")
      get path

      assert_includes 200..399, response.status,
        "#{path} returned #{response.status}#{error_summary}"

      # An index showing ActiveAdmin's empty state only tested the empty branch.
      if key.end_with?("#index") && !EMPTY_INDEX_OK.key?(key)
        assert_select ".blank_slate", false,
          "#{path} rendered empty; add fixtures (or list it in EMPTY_INDEX_OK with a reason)"
      end
    end
  end

  private

  def build_path(key, template)
    template.gsub(/:(\w+)/) do
      name = Regexp.last_match(1).to_sym
      if name == :id
        record_id_for(key)
      else
        PARAM_VALUES.fetch(name) { flunk "#{key}: add a value for :#{name} to PARAM_VALUES or SKIP it" }.call
      end
    end
  end

  def seed_inline_record(key)
    model = model_for(key.split("#").first)
    instance_exec(&INLINE_RECORDS[model]) if INLINE_RECORDS.key?(model) && !model.exists?
  rescue NameError
    # A custom page (e.g. admin/cache) rather than a resource.
  end

  def record_id_for(key)
    model = model_for(key.split("#").first)
    record = model.first || (seed = INLINE_RECORDS[model]) && instance_exec(&seed)
    assert record, "#{key}: no #{model} rows to render; add a fixture or an INLINE_RECORDS entry"
    record.to_param
  end

  # ActiveAdmin knows its resource class; plain admin controllers (e.g. error
  # events) are named after their model.
  def model_for(controller)
    klass = "#{controller.camelize}Controller".constantize
    return klass.active_admin_config.resource_class if klass.respond_to?(:active_admin_config)

    controller.delete_prefix("admin/").classify.constantize
  end

  def error_summary
    return "" unless response.status >= 500

    "\n#{response.body[/<h1>.*?<\/h1>|[A-Z]\w+(::\w+)*Error[^<\n]*/m].to_s.strip.first(300)}"
  end
end
