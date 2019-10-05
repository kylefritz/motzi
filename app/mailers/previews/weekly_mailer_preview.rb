
class WeeklyMailerPreview < ActionMailer::Preview
  def weekly_email
    WeeklyMailer.with(menu: @menu).welcome_email
  end
end
