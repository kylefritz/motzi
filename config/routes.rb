Rails.application.routes.draw do
  devise_for :users
  ActiveAdmin.routes(self)

  root to: "home#show"
  
  # preview other menus
  get "/menu/:id", to: "menu#show"

  # get the menu for the week
  get "/menu", to: "menu#show"  

  # create a subscribers order for the week
  post "/orders", to: "orders#create"

  # sign in
  get '/auth' => redirect('/users/sign_in')
  get '/login' => redirect('/users/sign_in')
  get '/signin' => redirect('/users/sign_in')

  # sign out
  get '/logout' => redirect('/signout')
  get '/signout' => 'home#signout'

  # review emails in development
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
