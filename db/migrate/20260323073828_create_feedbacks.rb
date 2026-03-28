class CreateFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :feedbacks do |t|
      t.string :source, null: false
      t.text :message, null: false
      t.string :email
      t.string :url
      t.string :user_agent

      t.datetime :created_at, null: false
    end
  end
end
