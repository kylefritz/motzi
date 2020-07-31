class FixEmailMissingLastLetter < ActiveRecord::Migration[6.0]
  def up
    too_short = User.pluck(:email).map do |email|
      email.split('.')[-1]
    end.select do |top_level|
      top_level.length == 2
    end.each_with_object(Hash.new(0)) { |val, counts| counts[val] += 1 }
    puts "found to fix: #{too_short}"

    com = 0
    edu = 0
    net = 0
    dup = 0

    bar = ProgressBar.new(User.count)
    User.find_each do |u|
      if u.email.ends_with? ".co"
        u.email += "m"
        u.save!
        com += 1
      elsif u.email.ends_with? ".ed"
        u.email += "u"
        u.save!
        edu += 1
      elsif u.email.ends_with? ".ne"
        u.email += "t"
        u.save!
        net += 1
      end
      bar.increment!
    rescue ActiveRecord::RecordInvalid
      original_user_id = User.find_by(email: u.email).id

      # transfer orders & credit_items
      u.orders.update_all(user_id: original_user_id)
      u.credit_items.update_all(user_id: original_user_id)

      # delete duplicate
      u.destroy!
      dup += 1
      bar.increment!
    end
    total = com + edu + net + dup
    puts "fixed #{total} com=#{com} edu=#{edu} net=#{net} dup=#{dup}"
  end
  def down
  end
end
