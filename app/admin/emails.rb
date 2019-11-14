ActiveAdmin.register Ahoy::Message, as: "Email" do
  actions :index, :show
  includes :menu, :user
  scope("all") { |scope| scope }
  scope("current menu") { |scope| scope.where(menu_id: Setting.menu_id) }

  index do
    column :to do |email|
      div auto_link email.to
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
    # column :mailer
  end
end
