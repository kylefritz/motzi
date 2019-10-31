module RenderCurrentOrder
  extend ActiveSupport::Concern
  
  included do
    protected

    def render_current_order
      @menu = Menu.current
      @user = current_user
      @order = current_user.current_order
      render 'menu/show', format: :json
    end
  end
end