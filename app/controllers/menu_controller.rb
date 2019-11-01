class MenuController < ApplicationController
  include UserHashidable
  include RenderCurrentOrder
  skip_before_action :require_hashid_user_or_devise_user!

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json do
         # if params[:id] not present, show current menu
        return render_current_order params[:id]
      end
    end
  end
end
