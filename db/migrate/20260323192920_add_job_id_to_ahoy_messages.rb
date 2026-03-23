class AddJobIdToAhoyMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :ahoy_messages, :job_id, :string
  end
end
