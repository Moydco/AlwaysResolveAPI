ApiMoydCo::Application.routes.draw do

  root "semi_static#index"

  api_version(:module => "V1", :path => {:value => "v1"}, :default => true) do
    resources :dns_datas, :only => [:index, :show] do
      collection do
        get :check_list
        post :query_count
        post 'update_from_check/:id', :to => "dns_datas#update_from_check", :as => 'update_from_check'
      end
    end
    resources :regions, :only => [:index, :show, :create, :update, :destroy] do
      resources :dns_server_statuses, :only => [:index, :create]
      resources :dns_server_logs, :only => [:index, :create]
      resources :neighbors, :only => [:index, :show, :create, :update, :destroy]
    end

    resources :users, :only => [:index, :show, :destroy ] do
      resources :api_accounts, :only => [:index, :show, :create, :update, :destroy]
      resources :checks, :only => [:index, :show, :create, :update, :destroy] do
        member do
          get :show_records
          put :passive_update
        end
      end
      resources :domains, :only => [:index, :show, :create, :update, :destroy] do
        resources :records, :only => [:index, :show, :create, :update, :destroy]do
          member do
            put :update_link
            get :old_version
            put :redo_version
          end
        end
        member do
          get :daily_stat
          get :monthly_total
        end
      end
    end
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
