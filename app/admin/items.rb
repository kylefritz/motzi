ActiveAdmin.register Item do
  permit_params :name, :description, :image, :price, :credits
  includes image_attachment: :blob
  config.sort_order = 'LOWER(name)'
  config.create_another = true

  actions :all, except: [:destroy] # deleting items can orphan orders, etc

  filter :menus
  filter :name
  filter :description
  filter :price
  filter :credits

  index do
    id_column
    column :name do |item|
      auto_link item
    end
    column :image do |item|
      if item.image.attached?
        if item.image.representable?
          span link_to(image_tag(item.image.representation(resize_to_limit: [100, 100]), alt: item.name), admin_item_path(item))
        else
          render partial: "not_representable"
        end
      end
    end
    column :credits
    column :price do |item|
      number_to_currency(item.price)
    end
    column :description
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :name
      row :credits
      row :price
      row :description
      row :image do |item|
        if item.image.attached?
          if item.image.representable?
            image_tag(item.image.representation(resize_to_limit: [250, 250]), alt: item.name)
          else
            render partial: "not_representable"
          end
        end
      end
    end

    active_admin_comments
  end

  form partial: 'form'
end
