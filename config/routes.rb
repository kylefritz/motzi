Rails.application.routes.draw do
  devise_for :users
  ActiveAdmin.routes(self)

  root to: "welcome#show"
  
  # get the menu for the week
  get "/menu", to: "menu#show"

  # create a subscribers order for the week
  post "/orders", to: "orders#create"

  # review emails in development
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
