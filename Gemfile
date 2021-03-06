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

source 'http://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
#gem 'rails', '4.0.0'
gem 'rails-api'
gem 'versionist'
gem 'activeresource'
gem 'actionmailer'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# TDD
group :development, :test do
  gem 'rspec-rails'
  gem 'mongoid-rspec', '~> 2.1.0'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
end

group :test do
  gem 'faker'
  gem 'capybara'
  gem 'guard-rspec'
  gem 'launchy'
end

# Use Unicorn as the app server
gem 'unicorn'

# Use Capistrano for deployment
gem 'capistrano',         group: :development
gem 'capistrano-bundler', group: :development
gem 'capistrano-rails',   group: :development
gem 'capistrano-rvm',     group: :development
gem 'capistrano-ext',     group: :development

# Use debugger
#gem 'debugger', group: [:development, :test]

# RabbitMQ Integration
gem 'bunny'

# Configuration
gem 'rails_config'

# Mongodb
gem 'mongoid', github: 'mongoid/mongoid'
gem 'bson', '~> 2.2'
#gem "bson_ext", '~> 1.8.6'
gem 'mongoid-slug' #, github: 'digitalplaywright/mongoid-slug'
gem 'mongoid_delorean'
gem 'kaminari'

# Background jobs
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'sidekiq'
gem 'redis'

# API intercommunication
gem 'httparty'
gem 'jwt'
gem 'rack-cors', :require => 'rack/cors'

# monitor
gem 'newrelic_rpm'

# daemons
gem 'daemons-rails'

