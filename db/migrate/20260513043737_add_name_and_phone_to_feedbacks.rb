class AddNameAndPhoneToFeedbacks < ActiveRecord::Migration[7.2]
  def change
    add_column :feedbacks, :name, :string
    add_column :feedbacks, :phone, :string
  end
end
