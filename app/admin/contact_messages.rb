ActiveAdmin.register ContactMessage do
  menu parent: 'Advanced', label: 'Contact Messages', priority: 50

  actions :index, :show, :destroy

  config.filters = false
  config.sort_order = 'created_at_desc'

  index do
    selectable_column
    column :created_at, sortable: :created_at do |msg|
      msg.created_at.strftime("%-m/%-d %l:%M%P")
    end
    column :name
    column :email
    column :phone
    column :message do |msg|
      truncate(msg.message, length: 80)
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :created_at
      row :name
      row :email do |msg|
        link_to(msg.email, "mailto:#{msg.email}") if msg.email.present?
      end
      row :phone
      row :message
      row :ip
      row :user_agent
    end
  end
end
