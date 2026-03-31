Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations" }
  ActiveAdmin.routes(self)

  root to: "home#show"

  # pay for credit items
  resources :credit_items, only: [ :new, :create ]

  # preview other menus
  resources :menus, only: [ :show ]

  # get the menu for the week
  get "/menu", to: "menus#show", as: :current_menu

  # create/update order for a menu
  resources :orders, only: [ :create, :update ]

  # email preference settings
  resource :email_preferences, only: [ :update ]

  # sign in
  get "/auth" => redirect("/users/sign_in")
  get "/login" => redirect("/users/sign_in")
  get "/signin" => redirect("/users/sign_in")

  # sign out
  get "/logout" => redirect("/signout")
  get "/signout" => "home#signout"

  # mounted admin-only apps
  authenticate :user, ->(user) { user.is_admin? } do
    get "/admin/pickup_lists/:date", to: "admin/pickup_lists#show", as: :admin_pickup_list

    mount Blazer::Engine, at: "/blazer"
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  # Error feedback API (used by error pages)
  namespace :api do
    resources :feedbacks, only: [ :create ]
  end

  # Custom error pages (404/422 are controller-rendered; 500 falls through to public/500.html)
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  # review emails in development
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    get "/dev/login_as_admin", to: "dev#login_as_admin"
  end
end
