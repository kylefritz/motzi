class SendWeeklyMenuJob < ApplicationJob
  queue_as :default

  def self.users_to_email_count(menu)
    users_to_email(menu).count
  end

  def perform(*args)
    menu = Menu.current

    # email each individual user
    self.class.users_to_email(menu).find_each do |user|
      # Changed on 1/31/2022 to deliver_later. Maybe should use args to decide between deliver_now & deliver_later.
      MenuMailer.with(menu: menu, user: user).weekly_menu_email.deliver_later
    end

    # TODO: ideas to "fix" send_weekly_menu_job
    #
    # Add recurring job that looks for current menu and then looks for the "emailed at" comment on the menu.
    # If the comment is there but there are not enough emails in the database, re-run SendWeeklyMenuJob
    #
  end

  def self.users_to_email(menu)
    # dont send to same people twice
    already_got_menu = Set[*menu.messages.where(mailer: 'MenuMailer#weekly_menu_email').pluck(:user_id)]
    User.subscribers.where.not(id: already_got_menu)
  end
end
