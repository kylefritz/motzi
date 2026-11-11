class RegistrationsController < Devise::RegistrationsController
  include TurnstileVerifiable

  before_action :check_turnstile, only: :create

  # Devise's default deletes the account, and with it every order and credit
  # the member has (dependent: :destroy). Closing an account goes through the
  # bakery instead, the same as in the admin, which won't delete a member who
  # has orders.
  def destroy
    redirect_to edit_user_registration_path,
                alert: "To close your account, email us at #{Setting.shop.email_reply_to}."
  end

  private

  def check_turnstile
    return unless ENV["TURNSTILE_SECRET_KEY"].present?

    token = params["cf-turnstile-response"]
    reject_as_bot unless verify_turnstile_token(token, remoteip: request.remote_ip)
  end

  def reject_as_bot
    set_flash_message(:alert, :turnstile_failed)
    redirect_to new_registration_path(resource_name)
  end
end
