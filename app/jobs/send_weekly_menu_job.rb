class SendWeeklyMenuJob < ApplicationJob
  queue_as :default

  def self.users_to_email_count(menu)
    users_to_email(menu).count
  end

  def perform(*args)
    menu = Menu.current

    # email each individual user
    self.class.users_to_email(menu).find_each do |user|
      MenuMailer.with(menu: menu, user: user).weekly_menu_email.deliver_now
    end
  end

  def self.users_to_email(menu)
    # dont send to same people twice
    already_got_menu = Set[*menu.messages.where(mailer: 'MenuMailer#weekly_menu_email').pluck(:user_id)]
    User.subscribers.where.not(id: already_got_menu)
  end
end
