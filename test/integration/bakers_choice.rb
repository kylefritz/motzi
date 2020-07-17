require 'test_helper'

class WhatToBakeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "bakers_choice" do
    get "/admin/menus/bakers_choice"
    assert_response :success

    gon_footer = document_root_element.css('.gon_footer').to_s
    assert gon_footer.include?('gon.haventOrdered')
    assert gon_footer.include?('Adrian')
    assert gon_footer.include?(users(:adrian).id.to_s)
    assert gon_footer.include?('gon.menu')
    assert gon_footer.include?(Menu.current.id.to_s)
  end
end
