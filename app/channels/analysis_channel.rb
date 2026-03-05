class AnalysisChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user.is_admin?
    stream_from "analysis_#{params[:week_id]}"
  end
end
