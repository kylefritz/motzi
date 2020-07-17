class MergeFeedbackAndComments < ActiveRecord::Migration[6.0]
  def up
    bar = ProgressBar.new(Order.count)
    Order.find_each do |o|
      combined_feedback = [o.feedback, o.comments].reject(&:blank?).join("\n\n------------\n\n")
      if combined_feedback.present?
        o.update!(feedback: nil, comments: combined_feedback)
      end
      bar.increment!
    end

    remove_column :orders, :feedback
  end
  def down
    add_column :orders, :feedback, :string
  end
end
