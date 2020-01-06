ActiveAdmin.register Item do
  permit_params :name, :description, :image
  config.sort_order = 'LOWER(name)'
  config.create_another = true

  index do
    selectable_column
    column :name do |item|
      auto_link item
    end
    column :image do |item|
      if item.image.attached?
        span link_to(image_tag(item.image.representation(resize_to_limit: [100, 100]), alt: item.name), admin_item_path(item))
      end
    end
    column :description
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :name
      row :description
      row :image do |item|
        if item.image.attached?
          image_tag(item.image.representation(resize_to_limit: [250, 250]), alt: item.name)
        end
      end
    end
  end

  form partial: 'form'
end
