# Helpers available inside fixture ERB.
#
# Admin dashboards (activity feed, uptime, error events) default to the
# current week, so ops fixtures have to land in it or those pages only ever
# render their empty state. That's how the Dyno Memory OpenStruct crash
# (error_events #2312) shipped.
module FixtureHelpers
  # `ago` before now, but never before the start of the current week, so rows
  # stay in the week the dashboards show whatever day the suite runs.
  def this_week(ago = 0)
    week_start = Time.zone.from_week_id(Time.zone.now.week_id)
    [ Time.zone.now - ago, week_start ].max.to_fs(:db)
  end
end

ActiveRecord::FixtureSet.context_class.include(FixtureHelpers)
