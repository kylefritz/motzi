ActiveAdmin.register PaperTrail::Version, as: 'Version' do
  menu parent: 'Developer', priority: 6
  actions :index, :show
end
