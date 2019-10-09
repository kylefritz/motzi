class MenuController < ApplicationController
  before_filter :maybe_sign_in_by_hash_id
  def show
    @menu = Menu.current
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @menu }
    end
  end

  private
  def maybe_sign_in_by_hash_id
    if hashid = params[:uid] && user = Person.find_by_hashid(hashid)
      # regular users can use hashid for easy sign-in
      unless user.is_admin?
        logger.info "signin user=#{user.email} via_hashid=#{hashid}"
        sign_in(user)
      end
    end
  end
end
