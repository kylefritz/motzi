ActiveAdmin.register Item do
  permit_params :name, :description, :image
  config.sort_order = 'name_asc'

  index as: :grid, columns: 5 do |item|
    div for: item do
      resource_selection_cell item
      span  link_to(item.name, admin_item_path(item))
      if item.image.attached?
        span link_to(image_tag(item.image, size: "100x100", alt: item.name), admin_item_path(item))
      end
    end
  end

  show do
    attributes_table do
      row :name
      row :description
      row :image do |item|
        if item.image.attached?
          image_tag url_for(item.image)
        end
      end
    end
  end

  form partial: 'form'
end
