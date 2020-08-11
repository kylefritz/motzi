ActiveAdmin.register Ahoy::Message, as: "Email" do
  actions :all, except: [:edit, :update] # updating doesn't make sense
  includes :menu, :user

  scope :all, default: true
  scope("current menu") { |scope| scope.where(menu_id: Setting.menu_id) }

  preserve_default_filters!
  remove_filter :token

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
    column :sent_at
    column :opened_at
    column :clicked_at
    column :subject
    actions
  end
end
