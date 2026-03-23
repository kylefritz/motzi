ActiveAdmin.register Ahoy::Visit, as: 'Visit' do
  menu parent: 'Developer', priority: 7

  actions :index, :show

  config.sort_order = 'started_at_desc'

  filter :created_at
  filter :started_at
  filter :user_id_equals
  filter :browser
  filter :device_type
  filter :referring_domain
  filter :city
  filter :country

  scope :all, default: true
  scope('With user') { |s| s.where.not(user_id: nil) }

  index do
    column :started_at
    column('User') { |v| v.user ? link_to(v.user.name, admin_user_path(v.user)) : v.visitor_token.first(8) }
    column :browser
    column :device_type
    column :referring_domain
    column('Location') { |v| [v.city, v.region, v.country].compact_blank.join(', ') }
    column('Page') do |v|
      path = v.landing_page&.gsub(%r{https?://[^/]+}, '')
      if path
        short = path.gsub(/\?.*/, '')
        short += '?…' if path.include?('?')
        span short, title: path
      end
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :started_at
      row('User') { |v| v.user ? link_to(v.user.name, admin_user_path(v.user)) : 'Anonymous' }
      row :visitor_token
      row :visit_token
      row :ip
      row :browser
      row :os
      row :device_type
      row :referring_domain
      row :referrer
      row :landing_page
      row('Location') { |v| [v.city, v.region, v.country].compact_blank.join(', ') }
      row :utm_source
      row :utm_medium
      row :utm_campaign
      row :user_agent
    end
  end
end
