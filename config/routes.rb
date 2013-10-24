ApiMoydCo::Application.routes.draw do

  root "semi_static#index"

  api_version(:module => "V1", :path => {:value => "v1"}, :default => true) do
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
