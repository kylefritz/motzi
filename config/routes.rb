Rails.application.routes.draw do
  devise_for :users
  ActiveAdmin.routes(self)

  root to: "home#show"

  # pay for credit items
  resources :credit_items, only: [:new, :create]

  # preview other menus
  resources :menus, only: [:show]

  # get the menu for the week
  get "/menu", to: "menus#show", as: :current_menu

  # create/update order for a menu
  resources :orders, only: [:create, :update]

  # sign in
  get '/auth' => redirect('/users/sign_in')
  get '/login' => redirect('/users/sign_in')
  get '/signin' => redirect('/users/sign_in')

  # sign out
  get '/logout' => redirect('/signout')
  get '/signout' => 'home#signout'

  # blazer for admins
  authenticate :user, ->(user) { user.is_admin? } do
    mount Blazer::Engine, at: "blazer"
  end

  # review emails in development
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
