class EmailPreferencesController < ApplicationController
  include UserHashidable

  before_action :require_hashid_user_or_devise_user!

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
