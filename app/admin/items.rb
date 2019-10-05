ActiveAdmin.register Item do
  permit_params :name, :description, :image

  form partial: 'form'
end
