ActiveAdmin.register Item do
  menu priority: 3
  permit_params :name, :description, :image, :price, :credits
  includes image_attachment: :blob
  config.sort_order = 'LOWER(name)'
  config.create_another = true

  actions :all, except: [:destroy]

  # The menu builder fetches /admin/items.json — only return active items
  controller do
    def scoped_collection
      collection = super
      if request.format.json? && collection.column_names.include?("archived_at")
        collection.active
      else
        collection
      end
    end
  end

  filter :menus
  filter :name
  filter :description
  filter :price
  filter :credits
  filter :archived_at, as: :select, collection: [["Active", "active"], ["Archived", "archived"]], label: "Status"

  scope :all, default: true
  scope :active
  scope :archived

  index do
    id_column
    column :name do |item|
      span class: ("archived-item" if item.archived?) do
        auto_link item
        if item.archived?
          status_tag "archived", class: "small"
        end
      end
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
      row :status do |item|
        if item.archived?
          status_tag "Archived since #{item.archived_at.strftime('%-m/%-d/%Y')}", class: "warning"
        else
          status_tag "Active", class: "ok"
        end
      end
      row :image do |item|
        if item.image.attached?
          if item.image.representable?
            image_tag(item.image.representation(resize_to_limit: [250, 250]), alt: item.name)
          else
            render partial: "not_representable"
          end
        end
      end
      row :menus do |item|
        item.menus.count
      end
      row :orders do |item|
        item.order_items.count
      end
    end

    panel "Actions" do
      if resource.archived?
        para link_to("Unarchive — make available in menu builder", unarchive_admin_item_path(resource), method: :put, class: "button")
      else
        para link_to("Archive — hide from menu builder", archive_admin_item_path(resource), method: :put, class: "button", data: { confirm: "Archive this item? It will be hidden from the menu builder but preserved in order history." })
      end

      if resource.deletable?
        para link_to("Delete permanently", delete_item_admin_item_path(resource), method: :delete, class: "button", style: "background: #b00; border-color: #b00;", data: { confirm: "Permanently delete #{resource.name}? This cannot be undone." })
      else
        para "This item cannot be deleted because it has #{resource.menu_items.count} menu appearances and #{resource.order_items.count} orders.", style: "color: #999; font-size: 13px;"
      end
    end

    active_admin_comments
  end

  member_action :archive, method: :put do
    resource.archive!
    redirect_to admin_item_path(resource), notice: "#{resource.name} archived — hidden from menu builder."
  end

  member_action :unarchive, method: :put do
    resource.unarchive!
    redirect_to admin_item_path(resource), notice: "#{resource.name} unarchived — now available in menu builder."
  end

  member_action :delete_item, method: :delete do
    if resource.deletable?
      name = resource.name
      resource.destroy!
      redirect_to admin_items_path, notice: "#{name} permanently deleted."
    else
      redirect_to admin_item_path(resource), alert: "Cannot delete — this item has menu appearances or orders."
    end
  end

  form partial: 'form'
end
