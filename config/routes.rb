# --------------------------------------------------------------------------- #
# Copyright 2013-2015, AlwaysResolve Project (alwaysresolve.org), MOYD.CO LTD #
#                                                                             #
# Licensed under the Apache License, Version 2.0 (the "License"); you may     #
# not use this file except in compliance with the License. You may obtain     #
# a copy of the License at                                                    #
#                                                                             #
# http://www.apache.org/licenses/LICENSE-2.0                                  #
#                                                                             #
# Unless required by applicable law or agreed to in writing, software         #
# distributed under the License is distributed on an "AS IS" BASIS,           #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    #
# See the License for the specific language governing permissions and         #
# limitations under the License.                                              #
# --------------------------------------------------------------------------- #


ApiMoydCo::Application.routes.draw do

  root "semi_static#index"

  api_version(:module => "V1", :path => {:value => "v1"}, :default => true) do

    resources :sessions, :only => [ :destroy ]
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
      resources :regdom, :only => [:index] do
        collection do
          resources :contacts, :only => [:index, :show, :create, :update]
          resources :domain_registrations do
            resources :dns, :only => [ :index, :create, :update, :delete]
            collection do
              post :transfer
            end
            member do
              post :renew
              put :lock
              put :unlock
              get :epp_key
            end
          end
        end
      end
      collection do
        get :credit
      end
      resources :api_accounts, :only => [:index, :show, :create, :update, :destroy]
      resources :checks, :only => [:index, :show, :create, :update, :destroy] do
        member do
          get :show_records
          put :passive_update
          get :show_url
        end
      end
      resources :domains, :only => [:index, :show, :create, :update, :destroy] do
        resources :records, :only => [:index, :show, :create, :update, :destroy]do
          member do
            put :update_link
            get :old_versions
            put :redo_version
            put :trash
            put :untrash
            put :undo
          end
          collection do
            post :empty_trash
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
