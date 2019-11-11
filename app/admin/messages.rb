ActiveAdmin.register Ahoy::Message, as: "Email" do
  actions :index, :show
  scope("all") { |scope| scope }
  scope("current menu") { |scope| scope.where(menu_id: Setting.menu_id) }
end