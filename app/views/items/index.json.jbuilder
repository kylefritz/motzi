json.items @items.map do |item|
  json.extract! item, :id, :name, :description, :image_path
end
