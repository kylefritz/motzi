ActiveAdmin.register PaperTrail::Version, as: "Version" do
  menu parent: "Advanced", priority: 8
  actions :index, :show
end
