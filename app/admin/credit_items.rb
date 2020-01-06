ActiveAdmin.register CreditItem do
  permit_params :memo, :good_for_weeks, :quantity, :user, :user_id
  includes :user

  preserve_default_filters!
  remove_filter :versions
end
