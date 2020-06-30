class MenusController < ApplicationController
  include UserHashidable
  include RenderCurrentOrder

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
