class ReplyIngressController < ActionController::API
  before_action :authenticate!

  def create
    analysis = AnomalyAnalysis.find_by(id: params[:in_reply_to].to_s[/analysis-(\d+)@/, 1])
    return render json: { error: "Unknown analysis" }, status: :not_found unless analysis

    author_email = params[:from_email].to_s.downcase
    user = User.find_by(email: author_email)

    unless user&.is_admin?
      return render json: { error: "Sender not authorized" }, status: :forbidden
    end

    reply = analysis.replies.create!(
      user: user,
      author_email: author_email,
      author_name: params[:from_name],
      body: strip_quoted(params[:body]),
      message_id: params[:message_id],
      source: :email
    )

    render json: { id: reply.id }, status: :created
  rescue ActiveRecord::RecordNotUnique
    render json: { status: "duplicate" }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  end

  private

  def authenticate!
    expected = ENV["REPLY_WEBHOOK_SECRET"].to_s
    token = request.headers["Authorization"].to_s.sub(/^Bearer /, "")
    return if expected.present? &&
              token.bytesize == expected.bytesize &&
              ActiveSupport::SecurityUtils.secure_compare(token, expected)

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def strip_quoted(body)
    body.to_s.split(/^(On .+ wrote:|>.*|-+Original Message-+)/).first.to_s.strip
  end
end
