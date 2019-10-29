class MenuController < ApplicationController
  def show
    
    respond_to do |format|
      format.html # show.html.erb
      format.json do
        @menu = Menu.current
        # show.json.jbuilder
      end
    end
  end
end
