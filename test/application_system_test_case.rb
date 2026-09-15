require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Headless so it runs on CI; set SYSTEM_TEST_HEADFUL=1 to watch locally.
  driven_by :selenium, using: (ENV["SYSTEM_TEST_HEADFUL"] ? :chrome : :headless_chrome), screen_size: [ 1400, 1400 ]
end
