class ArchiveStaleItems < ActiveRecord::Migration[7.2]
  def up
    now = Time.current

    # 1. "DON'T USE" items (e.g. #74 "Chocolate Chip Cookies DON'T USE")
    dont_use_ids = exec_query("SELECT id FROM items WHERE name ILIKE '%don_t use%' AND archived_at IS NULL").rows.flatten

    # 2. Blank/empty name — abandoned "slot" items from 2020-2021
    blank_ids = exec_query("SELECT id FROM items WHERE (name IS NULL OR TRIM(name) = '') AND archived_at IS NULL").rows.flatten

    # 3. Never appeared on any menu (excludes Pay It Forward sentinel)
    never_ids = exec_query(<<~SQL).rows.flatten
      SELECT i.id FROM items i
      LEFT JOIN menu_items mi ON mi.item_id = i.id
      WHERE mi.id IS NULL AND i.archived_at IS NULL AND i.id != -1
    SQL

    all_ids = (dont_use_ids + blank_ids + never_ids).uniq
    return say("No items to archive") if all_ids.empty?

    count = exec_update("UPDATE items SET archived_at = '#{now.iso8601}' WHERE id IN (#{all_ids.join(',')})")
    say "Archived #{count} stale items (#{dont_use_ids.size} DON'T USE, #{blank_ids.size} blank-name, #{never_ids.size} never-on-menu)"
  end

  def down
    exec_update("UPDATE items SET archived_at = NULL WHERE archived_at IS NOT NULL")
  end
end
