module RenderCurrentOrder
  extend ActiveSupport::Concern

  included do
    protected

    def render_current_order(menu_id=nil, user=nil)
      @menu = menu_id ? Menu.find(menu_id) : Menu.current
      @user = user || current_user
      @order = @user&.order_for_menu(@menu)
      render 'menus/show', format: :json
    end
  end
end