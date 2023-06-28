Rails.application.routes.draw do
  resources :results, only: %i[new create destroy] do
    member do
      get :download
    end
  end

  resources :surveys, only: %i[index show] do
    collection do
      get :analyze
    end
  end

  namespace :admin do
    resources :results, only: %i[index new create destroy] do
      member do
        get :download
      end
    end

    resources :surveys do
      member do
        get :users
        get :download_definition
        get :download_merged_results
        patch :aggregate_results
        patch :export_results
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
