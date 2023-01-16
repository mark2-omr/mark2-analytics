Rails.application.routes.draw do
  resources :results do
    member { get :download }
  end

  resources :surveys do
    member { get :download_definition }
  end

  resources :groups
  resources :users

  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "/sign_out", to: "sessions#destroy"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "welcome#index"
end
