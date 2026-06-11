ActiveAdmin.register ContactMessage do
  menu parent: 'Advanced', label: 'Contact Messages', priority: 50

  actions :index, :show, :destroy

  config.filters = false

  index do
    column :created_at do |msg|
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
      row :created_at
      row :name
      row :email
      row :phone
      row :message
      row :ip
      row :user_agent
    end
  end
end
