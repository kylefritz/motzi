class MenuController < ApplicationController
  include UserHashidable
  include RenderCurrentOrder
  skip_before_action :require_hashid_user_or_devise_user!

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json do
        return render_current_order
      end
    end
  end
end
