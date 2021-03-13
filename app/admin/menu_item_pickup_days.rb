ActiveAdmin.register MenuItemPickupDay do
  permit_params :menu_item_id, :pickup_day_id, :limit
  menu false

  # TODO: this route method & name is bad
  collection_action :find, method: :post do
    mipd = MenuItemPickupDay.find_by(menu_item_id: params[:menu_item_id], pickup_day_id: params[:pickup_day_id])
    mipd.destroy
    render json: {message: "deleted!"}
  end

end
