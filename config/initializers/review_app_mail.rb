class ReviewAppMailInterceptor
  mattr_accessor :active, default: false

  def self.delivering_email(message)
    allowed = User.admin.pluck(:email).map(&:downcase)
    message.cc = Array(message.cc).select { |addr| allowed.include?(addr.downcase) }
    message.bcc = Array(message.bcc).select { |addr| allowed.include?(addr.downcase) }
    filtered_to = Array(message.to).select { |addr| allowed.include?(addr.downcase) }

    if filtered_to.empty?
      message.perform_deliveries = false
    else
      message.to = filtered_to
    end
  end
end

if ENV['REVIEW_APP'].present?
  ActionMailer::Base.register_interceptor(ReviewAppMailInterceptor)
  ReviewAppMailInterceptor.active = true
end
