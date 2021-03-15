ActiveAdmin.register Ahoy::Message, as: "Email" do
  actions :all, except: [:edit, :update] # updating doesn't make sense
  includes :menu, :user, :pickup_day

  scope :all, default: true
  scope("current menu") { |scope| scope.where(menu_id: Setting.menu_id) }

  filter :menu
  filter :to
  filter :user_id_equals
  filter :subject
  filter :sent_at

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
    actions
  end
end
