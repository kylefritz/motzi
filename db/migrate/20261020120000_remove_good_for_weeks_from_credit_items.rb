# Credits don't expire (#431). CreditItem has ignored the column since v565,
# so no running code reads or writes it.
class RemoveGoodForWeeksFromCreditItems < ActiveRecord::Migration[8.1]
  def change
    remove_column :credit_items, :good_for_weeks, :integer
  end
end
