class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :push_gon

  def not_found
    render status: :not_found
  end

  def unprocessable
    render status: :unprocessable_entity
  end
end
