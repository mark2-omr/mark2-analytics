Rails.application.routes.draw do
  resources :results do
    member do
      get :download
    end
  end

  resources :surveys do
    collection do
      get :analyze
    end

    member do
      get :users
      get :download_definition
    end
  end

  namespace :admin do
    resources :results do
      member do
        get :download
      end
    end
    resources :groups
    resources :users
  end

  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  get '/sign_out', to: 'sessions#destroy'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root 'welcome#index'
end
