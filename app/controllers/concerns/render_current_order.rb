module RenderCurrentOrder
  extend ActiveSupport::Concern

  included do
    protected

    def render_current_order(menu_id=nil, user=nil)
      @menu = menu_id ? Menu.find(menu_id) : Menu.current
      @open_menus = Menu.open_for_ordering.to_a
      @open_menus << @menu if @menu.present? && !@open_menus.include?(@menu)
      @open_menus = @open_menus.uniq.sort_by { |menu| menu.week_id.to_s.downcase }.reverse
      @user = user || current_user
      @order = @user&.order_for_menu(@menu)
      render 'menus/show', format: :json
    end
  end
end
