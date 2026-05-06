class Admin::ErrorEventsController < ApplicationController
  before_action :redirect_unless_user_is_admin!
  before_action :load_event, only: [:show, :resolve, :unresolve]

  PER_PAGE = 30

  def index
    scope = ErrorEvent.all
    scope = scope.for_source(params[:source]) if params[:source].present?

    case params[:status]
    when "resolved"
      scope = scope.resolved
    when "all"
      # no filter
    else
      scope = scope.open
    end

    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.where("error_class ILIKE ? OR message ILIKE ?", q, q)
    end

    page = [params[:page].to_i, 1].max
    offset = (page - 1) * PER_PAGE

    @groups = scope
      .select("MAX(id) AS latest_id, fingerprint, COUNT(*) AS event_count, MAX(occurred_at) AS last_seen, MIN(occurred_at) AS first_seen, MAX(error_class) AS error_class, MAX(message) AS message, MAX(source) AS source")
      .group(:fingerprint)
      .order("MAX(occurred_at) DESC")
      .limit(PER_PAGE)
      .offset(offset)

    @page = page
    @latest_events = ErrorEvent.where(id: @groups.map(&:latest_id)).index_by(&:id)
    @status = params[:status].presence || "open"
    @source = params[:source]
    @q = params[:q]
  end

  def show
    @siblings = @event.siblings(limit: 20)
    @prompt = @event.to_claude_prompt

    respond_to do |format|
      format.html
      format.text { render plain: @prompt }
      format.json do
        render json: {
          event: @event.as_json,
          siblings: @siblings.as_json,
          claude_prompt: @prompt
        }
      end
    end
  end

  def resolve
    @event.resolve_group!
    redirect_to admin_error_event_path(@event), notice: "Resolved all events with this fingerprint."
  end

  def unresolve
    @event.unresolve_group!
    redirect_to admin_error_event_path(@event), notice: "Reopened all events with this fingerprint."
  end

  private

  def load_event
    @event = ErrorEvent.find(params[:id])
  end
end
