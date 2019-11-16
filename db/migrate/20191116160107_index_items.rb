class IndexItems < ActiveRecord::Migration[6.0]
  def change
    add_index :items, "LOWER(name)"
  end
end
