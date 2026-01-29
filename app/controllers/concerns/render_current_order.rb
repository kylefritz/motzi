module RenderCurrentOrder
  extend ActiveSupport::Concern

  included do
    protected

    def render_current_order(menu_id=nil, user=nil)
      requested_menu = menu_id ? Menu.find(menu_id) : nil
      open_menus = Menu.open_for_ordering.to_a
      open_menus << requested_menu if requested_menu.present?
      open_menus = order_open_menus(open_menus)

      @menu = requested_menu || select_primary_menu(open_menus) || Menu.current
      open_menus << @menu if @menu.present?
      @open_menus = order_open_menus(open_menus)

      @user = user || current_user
      @order = @user&.order_for_menu(@menu)
      render 'menus/show', format: :json
    end

    private

    def order_open_menus(menus)
      menus.compact.uniq { |menu| menu.id }.sort_by do |menu|
        week = menu.week_start
        is_special = menu.is_special? ? 1 : 0
        [is_special, -week.to_i]
      end
    end

    def select_primary_menu(menus)
      non_special = menus.reject(&:is_special?)
      return non_special.max_by { |menu| menu.week_start.to_i } if non_special.any?
      menus.max_by { |menu| menu.week_start.to_i }
    end

  end
end
