ActiveAdmin.register CreditEntry do
  permit_params :memo, :good_for_months, :quantity, :user, :user_id
end
