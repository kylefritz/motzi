ActiveAdmin.register CreditEntry do
  permit_params :memo, :good_for_weeks, :quantity, :user, :user_id
end
