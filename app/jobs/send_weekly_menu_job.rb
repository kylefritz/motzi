class SendWeeklyMenuJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # TODO: make SendWeeklyMenuJob smart like the other jobs are
    # shouldnt send to same people twice; might want to give it a schedule

    menu = Menu.current

    # email each individual user
    User.for_weekly_email.map do |user|
      MenuMailer.with(menu: menu, user: user).weekly_menu.deliver_now
    end
  end
end
