class MenuController < ApplicationController
  include UserHashidable
  include RenderCurrentOrder

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json do
        return render_current_order
      end
    end
  end
end
