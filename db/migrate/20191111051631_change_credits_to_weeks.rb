class ChangeCreditsToWeeks < ActiveRecord::Migration[6.0]
  def change
    rename_column :credit_entries, :good_for_months, :good_for_weeks
  end
end
