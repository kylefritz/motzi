module RenderCurrentOrder
  extend ActiveSupport::Concern

  included do
    protected

    def render_current_order(menu_id=nil)
      @menu = menu_id ? Menu.find(menu_id) : Menu.current
      @user = current_user
      @order = current_user&.order_for_menu(@menu)
      render 'menus/show', format: :json
    end
  end
end