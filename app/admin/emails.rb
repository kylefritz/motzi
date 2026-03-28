ActiveAdmin.register Ahoy::Message, as: "Email" do
  menu parent: 'Advanced', label: 'Emails', priority: 2
  actions :all, except: [:edit, :update] # updating doesn't make sense
  includes :menu, :user, :pickup_day

  scope :all, default: true
  scope("current menu") { |scope| scope.where(menu_id: Setting.menu_id) }

  filter :menu
  filter :to
  filter :user_id_equals
  filter :subject
  filter :sent_at
  filter :job_id
  filter :job_name

  index do
    selectable_column
    id_column
    column :to do |email|
      div auto_link email.user, email.to
    end
    column :user do |email|
      div auto_link email.user
    end
    column "menu" do |email|
      auto_link email.menu
    end
    column "pickup_day" do |email|
      auto_link email.pickup_day&.day_str
    end
    column :sent_at
    column :opened_at
    column :clicked_at
    column :subject
    column :job_name
    column :job_id do |email|
      if email.job_id
        link_to email.job_id.first(8), "/jobs/applications/motzi/jobs/#{email.job_id}", title: email.job_id
      end
    end
    actions
  end
end
