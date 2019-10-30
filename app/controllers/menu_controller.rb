class MenuController < ApplicationController
  include UserHashidable

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json do
        @menu = Menu.current
        @user = current_user
        # show.json.jbuilder
      end
    end
  end
end
