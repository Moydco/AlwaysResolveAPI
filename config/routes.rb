ApiMoydCo::Application.routes.draw do

  get "server_logs/index"
  get "server_logs/create"
  root "semi_static#index"

  api_version(:module => "V1", :path => {:value => "v1"}, :default => true) do
    resources :regions, :only => [:index, :show, :create, :update, :destroy] do
      resources :server_statuses, :only => [:index, :create] do
        resources :server_logs, :only => [:index, :create]
      end
    end
    resources :users, :only => [:index, :show ] do
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
end
