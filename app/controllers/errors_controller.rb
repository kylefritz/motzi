class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :push_gon

  def not_found
    render_error :not_found
  end

  def unprocessable
    render_error :unprocessable_entity
  end

  def internal_server_error
    render_error :internal_server_error, "errors/internal_server_error"
  end

  private

  # The error pages only exist as HTML. A stale asset fingerprint (Accept:
  # text/css) or a JSON request would otherwise hit a missing template and
  # turn a 404 into a 500. Browsers (and curl's */*) still get the page;
  # anything else gets the bare status. Plain text keeps OliveBranch from
  # rewriting an empty JSON body to "null".
  def render_error(status, template = action_name)
    if request.format.html? || request.format == Mime::ALL
      render template, status: status, formats: :html
    else
      head status, content_type: "text/plain"
    end
  end
end
