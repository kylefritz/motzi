class AddSubscriberToUser2 < ActiveRecord::Migration[6.0]
  def up
    User.where(subscriber: true).update_all(marketing_emails: true)
    User.where(id: [305, 306, 335, 342, 349, 361, 363]).update_all(marketing_emails: true, subscriber: false)
  end
  def down
  end
end
