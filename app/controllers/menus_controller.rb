class MenusController < ApplicationController
  include UserHashidable
  include RenderCurrentOrder

  before_action :require_open_menu_or_admin!

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json do
        # if params[:id] not present, show current menu
        return render_current_order params[:id]
      end
    end
  end

  private

  # /menus/:id is the admin's "Preview" of any menu, and the marketing nav's
  # link to the open holiday menu. Everyone else may only read the menus that
  # are open for orders (the current one and the current holiday menu): a
  # draft or past menu answers like a menu that doesn't exist.
  def require_open_menu_or_admin!
    return if params[:id].blank? || current_admin_user.present?

    open_menu_ids = [ Setting.menu_id, Setting.holiday_menu_id ].compact.map(&:to_s)
    raise ActiveRecord::RecordNotFound unless params[:id].to_s.in?(open_menu_ids)
  end
end
