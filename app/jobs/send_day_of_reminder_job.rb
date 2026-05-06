class SendDayOfReminderJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "send_day_of_reminder"

  def perform(*args)
    return unless Setting.automated_reminder_emails?
    return unless (7..11).include?(Time.zone.now.hour) # 7a-11a

    Rails.logger.info "[SendDayOfReminderJob] Starting job_id=#{job_id}"

    PickupDay.for_pickup_at(Time.zone.now).each do |pickup_day|

      next unless pickup_day.menu.current?

      send_reminders_for_day(pickup_day)
    end
  end

  private
  def send_reminders_for_day(pickup_day)
    menu = pickup_day.menu

    already_reminded = Set[*menu.messages.where(mailer: "ReminderMailer#day_of_email", pickup_day: pickup_day).pluck(:user_id)]

    num_reminded = 0

    # Iterate distinct users (not orders) to avoid sending duplicates
    # when a user has multiple orders on the same menu.
    user_ids = menu.orders.joins(:user)
      .where(users: { receive_day_of_reminder: true })
      .distinct.pluck(:user_id)

    User.where(id: user_ids).find_each do |user|
      next if already_reminded.include?(user.id)

      # Collect items across all of this user's orders for the pickup day
      order_items_for_day = menu.orders.where(user: user)
        .flat_map { |order| order.items_for_pickup(pickup_day) }

      next if order_items_for_day.empty?

      begin
        ReminderMailer.with(user: user,
                            menu: menu,
                            pickup_day: pickup_day,
                            order_items: order_items_for_day,
                            job_id: job_id,
                            job_name: self.class.name
                           ).day_of_email.deliver_now
        num_reminded += 1
      rescue => e
        Rails.logger.error "Failed to send reminder email to user #{user.id}: #{e.message}"
      end
    end

    if num_reminded > 0
      add_comment! menu, "Day Of reminder job: sent num_reminded=#{num_reminded}"
      ActivityEvent.log(
        action: "day_of_reminder_sent",
        week_id: menu.week_id,
        description: "Day-of reminder sent to #{num_reminded} members for #{pickup_day.name_abbr}",
        metadata: { menu_id: menu.id, pickup_day_id: pickup_day.id, count: num_reminded, job_id: job_id }
      )
    end

    check_for_duplicates(menu, "ReminderMailer#day_of_email", pickup_day)
  end

  def check_for_duplicates(menu, mailer, pickup_day)
    dupes = menu.messages.where(mailer: mailer, pickup_day: pickup_day)
      .group(:user_id).having("COUNT(*) > 1").count
    return if dupes.empty?

    Rails.logger.warn "[SendDayOfReminderJob] DUPLICATE SENDS DETECTED: #{dupes.size} users received #{mailer} more than once for menu #{menu.id}, pickup_day #{pickup_day.id} (job_id=#{job_id})"
    Rails.error.report(
      RuntimeError.new("Duplicate reminder emails detected"),
      handled: true,
      severity: :warning,
      context: { mailer: mailer, menu_id: menu.id, pickup_day_id: pickup_day.id, duplicate_count: dupes.size, job_id: job_id }
    )
  end
end
