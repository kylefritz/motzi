ActiveAdmin.register UptimeCheck do
  menu parent: "Advanced", label: "Uptime", priority: 6
  actions :index
  config.sort_order = "checked_at_desc"

  scope :all, default: true
  scope("failures") { |scope| scope.where(up: false) }

  filter :target, as: :select, collection: -> { UptimeCheck.distinct.pluck(:target).sort }
  filter :up
  filter :status
  filter :checked_at

  index do
    column :checked_at
    column :target
    column :up do |check|
      status_tag check.up ? "up" : "down", class: check.up ? "yes" : "no"
    end
    column :status
    column("Latency") { |check| check.latency_ms ? "#{check.latency_ms}ms" : "—" }
    column :error
    column :url
  end
end
