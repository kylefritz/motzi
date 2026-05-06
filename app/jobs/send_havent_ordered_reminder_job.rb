class SendHaventOrderedReminderJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "send_havent_ordered_reminder"

  def perform(*args)
    return unless Setting.automated_reminder_emails?

    Rails.logger.info "[SendHaventOrderedReminderJob] Starting job_id=#{job_id}"

    PickupDay.for_order_deadline_at(Time.zone.now).each do |pickup_day|
      send_reminders_for_day(pickup_day)
    end
  end

  private
  def send_reminders_for_day(pickup_day)
    menu = pickup_day.menu
    return unless menu.current?

    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#havent_ordered_email').pluck(:user_id)]
    already_ordered = Set[*menu.orders.pluck(:user_id)]

    num_reminded = 0

    User.receive_havent_ordered_reminder.find_each do |user|
      next if already_reminded.include?(user.id)
      next if already_ordered.include?(user.id)

      begin
        ReminderMailer.with(user: user, menu: menu, job_id: job_id, job_name: self.class.name).havent_ordered_email.deliver_now
        num_reminded += 1
      rescue => e
        Rails.logger.error "Failed to send haven't ordered email to user #{user.id}: #{e.message}"
      end
    end

    if num_reminded > 0
      add_comment! menu, "Haven't Ordered reminder job: num_reminded=#{num_reminded}"
      ActivityEvent.log(
        action: "havent_ordered_reminder_sent",
        week_id: menu.week_id,
        description: "Haven't-ordered reminder sent to #{num_reminded} recipients",
        metadata: { menu_id: menu.id, count: num_reminded, job_id: job_id }
      )
    end

    check_for_duplicates(menu, 'ReminderMailer#havent_ordered_email')
  end

  def check_for_duplicates(menu, mailer)
    dupes = menu.messages.where(mailer: mailer)
      .group(:user_id).having("COUNT(*) > 1").count
    return if dupes.empty?

    Rails.logger.warn "[SendHaventOrderedReminderJob] DUPLICATE SENDS DETECTED: #{dupes.size} users received #{mailer} more than once for menu #{menu.id} (job_id=#{job_id})"
    Rails.error.report(
      RuntimeError.new("Duplicate reminder emails detected"),
      handled: true,
      severity: :warning,
      context: { mailer: mailer, menu_id: menu.id, duplicate_count: dupes.size, job_id: job_id }
    )
  end
end
