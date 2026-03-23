class CreateErrorFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :error_feedbacks do |t|
      t.string :page_type, null: false
      t.text :message, null: false
      t.string :email
      t.string :url
      t.string :user_agent

      t.datetime :created_at, null: false
    end
  end
end
