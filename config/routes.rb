Rails.application.routes.draw do
  devise_for :users
  ActiveAdmin.routes(self)

  root to: "home#show"

  # preview other menus
  resources :menus, only: [:show]
  resources :credit_items, only: [:show, :create]

  # get the menu for the week
  get "/menu", to: "menus#show", as: :current_menu

  # create a subscribers order for the week
  post "/orders", to: "orders#create"

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
