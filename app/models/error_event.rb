require "digest"

class ErrorEvent < ApplicationRecord
  MESSAGE_LIMIT = 4_000
  BACKTRACE_LIMIT = 16_000
  STACK_FRAMES_FOR_PROMPT = 50

  SOURCES = %w[server browser job].freeze

  # 4xx noise we don't care about. Filtered in the Rails.error subscriber and
  # also as a defensive guard here so direct callers behave the same way.
  IGNORED_SERVER_EXCEPTIONS = %w[
    ActionController::RoutingError
    ActionController::ParameterMissing
    ActionController::InvalidAuthenticityToken
    ActionController::UnknownFormat
    ActionDispatch::Http::MimeNegotiation::InvalidType
    Mime::Type::InvalidMimeType
    ActiveRecord::RecordNotFound
  ].freeze

  belongs_to :user, optional: true

  validates :fingerprint, :source, :occurred_at, presence: true
  validates :source, inclusion: { in: SOURCES }

  scope :open, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }
  scope :for_source, ->(s) { where(source: s) if s.present? }

  def self.record_server_exception(exception, request: nil, user: nil, context: {}, status_code: nil)
    return if IGNORED_SERVER_EXCEPTIONS.include?(exception.class.name)

    backtrace = Array(exception.backtrace).first(200).join("\n")
    fingerprint = compute_fingerprint(
      error_class: exception.class.name,
      backtrace: exception.backtrace,
      url_path: request&.path
    )

    create!(
      fingerprint: fingerprint,
      source: "server",
      error_class: exception.class.name,
      message: truncate_message(exception.message),
      backtrace: truncate_backtrace(backtrace),
      url: request&.path,
      http_method: request&.method,
      status_code: status_code,
      request_id: request&.request_id,
      request_data: build_request_data(request),
      context: context.is_a?(Hash) ? context : { value: context.to_s },
      user_id: user&.id,
      environment: Rails.env,
      release: release_sha,
      occurred_at: Time.current
    )
  end

  def self.record_browser_exception(error_class:, message:, stack:, url:, context: {}, user: nil, request: nil)
    fingerprint = compute_fingerprint(
      error_class: error_class,
      backtrace: stack.to_s.lines,
      url_path: extract_path(url)
    )

    create!(
      fingerprint: fingerprint,
      source: "browser",
      error_class: error_class.presence || "Error",
      message: truncate_message(message),
      backtrace: truncate_backtrace(stack.to_s),
      url: extract_path(url),
      http_method: nil,
      status_code: nil,
      request_id: request&.request_id,
      request_data: build_request_data(request),
      context: context.is_a?(Hash) ? context : { value: context.to_s },
      user_id: user&.id,
      environment: Rails.env,
      release: release_sha,
      occurred_at: Time.current
    )
  end

  def self.compute_fingerprint(error_class:, backtrace:, url_path:)
    top_app_frame = Array(backtrace).find { |line| line.to_s.include?("/app/") } || Array(backtrace).first || ""
    Digest::SHA1.hexdigest([error_class, top_app_frame.to_s.split(":").first(2).join(":"), url_path].join("|"))[0, 16]
  end

  def self.release_sha
    @release_sha ||= ENV["HEROKU_SLUG_COMMIT"].presence || ENV["GIT_COMMIT"].presence || ENV["SOURCE_VERSION"].presence
  end

  def self.truncate_message(str)
    return nil if str.nil?
    str = str.to_s
    str.length > MESSAGE_LIMIT ? str[0, MESSAGE_LIMIT] : str
  end

  def self.truncate_backtrace(str)
    return nil if str.nil?
    str = str.to_s
    str.length > BACKTRACE_LIMIT ? str[0, BACKTRACE_LIMIT] : str
  end

  def self.build_request_data(request)
    return {} unless request

    filtered = filtered_params(request)
    {
      "params" => filtered,
      "ip" => request.remote_ip,
      "user_agent" => request.user_agent,
      "referer" => request.referer
    }.compact
  rescue StandardError
    {}
  end

  def self.filtered_params(request)
    params = request.respond_to?(:filtered_parameters) ? request.filtered_parameters : (request.params rescue {})
    filter = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
    filter.filter(params || {})
  rescue StandardError
    {}
  end

  def self.extract_path(url)
    return nil if url.blank?
    URI.parse(url).path
  rescue URI::InvalidURIError
    url.to_s.split("?", 2).first
  end

  def resolved?
    resolved_at.present?
  end

  def resolve_group!
    self.class.where(fingerprint: fingerprint, resolved_at: nil).update_all(resolved_at: Time.current, updated_at: Time.current)
  end

  def unresolve_group!
    self.class.where(fingerprint: fingerprint).where.not(resolved_at: nil).update_all(resolved_at: nil, updated_at: Time.current)
  end

  def siblings(limit: 20)
    self.class.where(fingerprint: fingerprint).where.not(id: id).order(occurred_at: :desc).limit(limit)
  end

  def to_claude_prompt
    user_line =
      if user
        "- **User**: #{user.email} (id: #{user.id})"
      else
        "- **User**: anonymous"
      end

    request_json =
      if request_data.present?
        JSON.pretty_generate(request_data)
      else
        "{}"
      end

    context_json =
      if context.present?
        JSON.pretty_generate(context)
      else
        "{}"
      end

    stack_lines = backtrace.to_s.split("\n").first(STACK_FRAMES_FOR_PROMPT).join("\n")
    url_line =
      if url.present? && http_method.present?
        "- **URL**: #{http_method} #{url}"
      elsif url.present?
        "- **URL**: #{url}"
      else
        nil
      end

    lines = []
    lines << "## #{error_class}: #{message}"
    lines << ""
    lines << "- **Source**: #{source}"
    lines << url_line if url_line
    lines << "- **Status**: #{status_code}" if status_code
    lines << user_line
    lines << "- **When**: #{occurred_at&.iso8601}"
    lines << "- **Env**: #{environment}#{release.present? ? " @ #{release[0, 12]}" : ""}"
    lines << "- **Request ID**: #{request_id}" if request_id.present?
    lines << ""
    lines << "### Stack trace"
    lines << "```"
    lines << stack_lines
    lines << "```"
    lines << ""
    lines << "### Request"
    lines << "```json"
    lines << request_json
    lines << "```"
    lines << ""
    lines << "### Context"
    lines << "```json"
    lines << context_json
    lines << "```"
    lines.join("\n")
  end
end
