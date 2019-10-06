ActiveAdmin.register Item do
  permit_params :memo, :good_for_months, :quantity, :user 
end