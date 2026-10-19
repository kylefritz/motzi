module UserHashidable
  extend ActiveSupport::Concern

  included do
    skip_before_action :authenticate_user!

    # we're going to change the definition of current_user
    # rename current_user to devise_user
    alias_method :devise_user, :current_user

    protected

    def current_user
      hashid_user || devise_user
    end

    def current_admin_user
      if devise_user&.is_admin?
        devise_user
      end
    end

    # An admin acting through a member's ?uid= link ("Order for" in the admin)
    # is the one making the change, so record them as whodunnit, not the member.
    def user_for_paper_trail
      (current_admin_user || current_user)&.id
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
