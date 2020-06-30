class StripDowncaseEmails < ActiveRecord::Migration[6.0]
  def up
    User.find_each do |user|
      clean_email = user.email.strip.downcase
      if clean_email != user.email
        user.update!(email: clean_email)
      end
    end
  end
  def down
  end
end
