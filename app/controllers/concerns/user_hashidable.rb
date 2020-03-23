module UserHashidable
  extend ActiveSupport::Concern

  included do
    skip_before_action :authenticate_user!
    before_action :require_hashid_user_or_devise_user!

    # we're going to change the definition of current_user
    # rename current_user to devise_user
    alias_method :devise_user, :current_user

    protected

    def current_user
      hashid_user || devise_user
    end

    def require_hashid_user_or_devise_user!
      if hashid_user
        logger.info "found user {#{hashid_user.name}} for hashid=#{hashid}"
      end

      unless current_user
        logger.info "womp no hashid; redirecting to login. params=#{params}"
        authenticate_user!
      end
    end

    def hashid
      params[:uid]
    end

    def hashid_user
      if hashid
        User.find_by_hashid(hashid)
      end
    end
  end
end