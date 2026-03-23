ActiveAdmin.register ErrorFeedback do
  menu priority: 13, label: "Error Feedback"
  actions :index, :show, :destroy

  filter :page_type, as: :select, collection: %w[404 422 500]
  filter :email
  filter :created_at

  index do
    selectable_column
    id_column
    column :page_type
    column :message do |f|
      truncate(f.message, length: 80)
    end
    column :email
    column :url do |f|
      truncate(f.url, length: 50) if f.url
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :page_type
      row :message
      row :email do |f|
        link_to(f.email, "mailto:#{f.email}") if f.email.present?
      end
      row :url
      row :user_agent
      row :created_at
    end
  end
end
