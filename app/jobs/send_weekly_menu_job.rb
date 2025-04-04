class SendWeeklyMenuJob < ApplicationJob
  queue_as :default

  def self.users_to_email_count(menu)
    users_to_email(menu).count
  end

  def perform(menu_id = nil)
    # Use the provided menu_id if available, otherwise fall back to current menu
    menu = menu_id ? Menu.find(menu_id) : Menu.current
    
    users = self.class.users_to_email(menu)
    count = users.count
    
    add_comment! menu, "SendWeeklyMenuJob: Starting to queue #{count} emails for menu #{menu.id}"
    
    # email each individual user
    users.find_each do |user|
      begin
        # Changed on 1/31/2022 to deliver_later.
        # Maybe should use args to decide between deliver_now & deliver_later.
        MenuMailer.with(menu: menu, user: user).weekly_menu_email.deliver_later
      rescue => e
        Rails.logger.error "Failed to send menu email to user #{user.id}: #{e.message}"
      end
    end
    
    add_comment! menu, "SendWeeklyMenuJob: Completed queueing #{count} emails for menu #{menu.id}"
    
    # TODO: ideas to "fix" send_weekly_menu_job
    #
    # Add recurring job that looks for current menu and then looks for the "emailed at" comment on the menu.
    # If the comment is there but there are not enough emails in the database, re-run SendWeeklyMenuJob
    #

    count # Return count of emails queued
  end

  def self.users_to_email(menu)
    # don't send to same people twice
    already_got_menu = Set[*menu.messages.where(mailer: 'MenuMailer#weekly_menu_email').pluck(:user_id)]
    User.subscribers.where.not(id: already_got_menu)
  end
end
