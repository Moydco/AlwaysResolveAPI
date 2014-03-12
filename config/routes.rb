ApiMoydCo::Application.routes.draw do

  get "neighbors/index"
  get "neighbors/show"
  get "neighbors/create"
  get "neighbors/update"
  get "neighbors/delete"
  root "semi_static#index"

  api_version(:module => "V1", :path => {:value => "v1"}, :default => true) do
    resources :dns_datas, :only => [:index, :show] do
      collection do
        get :check_list
      end
    end
    resources :regions, :only => [:index, :show, :create, :update, :destroy] do
      resources :dns_server_statuses, :only => [:index, :create]
      resources :dns_server_logs, :only => [:index, :create]
      resources :neighbors, :only => [:index, :show, :create, :update, :destroy]
    end

    resources :api_accounts, :only => [:show, :create, :update, :destroy]

    resources :users, :only => [:index, :show, :destroy ] do
      resources :api_accounts, :only => [:index, :show, :create, :update, :destroy]
      resources :domains, :only => [:index, :show, :create, :update, :destroy] do
        resources :records, :only => [:index, :show, :create, :update, :destroy]
        resources :clusters, :only => [:index, :show, :create, :update, :destroy] do

          resources :geo_locations, :only => [:index, :show, :create, :update, :destroy] do
            resources :geo_location_ips, :only => [:index, :show, :create, :update, :destroy]
          end
        end
      end
    end
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
