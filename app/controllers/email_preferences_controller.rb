class EmailPreferencesController < ApplicationController
  include UserHashidable

  before_action :require_hashid_user_or_devise_user!, except: :unsubscribe

  # One-click unsubscribe (RFC 8058). Our emails carry
  #   List-Unsubscribe: <…/menu?uid=…&tab=email>
  #   List-Unsubscribe-Post: List-Unsubscribe=One-Click
  # (ApplicationMailer), so the "Unsubscribe" button in Gmail, Yahoo and the
  # like POSTs that body to that URL, with no cookies. It turns off every
  # email the member can opt out of; order and credit confirmations have no
  # setting. Only the uid from the email counts, never a session: this is a
  # POST other sites could trigger.
  def unsubscribe
    user = hashid_user
    return head :not_found unless user
    return head :unprocessable_content unless params["List-Unsubscribe"] == "One-Click"

    user.update!(receive_weekly_menu: false, receive_havent_ordered_reminder: false, receive_day_of_reminder: false)
    logger.info "[EmailPreferences] one-click unsubscribe user_id=#{user.id}"
    render plain: "You're unsubscribed from #{Setting.shop.name} emails."
  end

  def update
    if current_user.update(email_preference_params)
      render json: {
        receive_weekly_menu: current_user.receive_weekly_menu,
        receive_havent_ordered_reminder: current_user.receive_havent_ordered_reminder,
        receive_day_of_reminder: current_user.receive_day_of_reminder
      }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def email_preference_params
    params.permit(:receive_weekly_menu, :receive_havent_ordered_reminder, :receive_day_of_reminder)
  end
end
