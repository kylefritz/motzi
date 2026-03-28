class AddJobNameToAhoyMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :ahoy_messages, :job_name, :string
  end
end
