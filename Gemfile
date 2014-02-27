ruby '1.9.3', :engine => 'jruby', :engine_version => '1.7.10'

source 'http://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
#gem 'rails', '4.0.0'
gem 'rails-api'
gem 'versionist'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use Puma as the app server
gem 'puma'

# Use Capistrano for deployment
gem 'capistrano', group: :development
gem 'capistrano-bundler', group: :development
gem 'capistrano-rails', group: :development
gem 'capistrano-rvm', group: :development
gem 'capistrano-ext', group: :development
gem 'newrelic_rpm'

# Use debugger
#gem 'debugger', group: [:development, :test]

# RabbitMQ Integration
gem "bunny"

# Configuration
gem 'rails_config'

# Mongodb
gem "mongoid", github: 'mongoid/mongoid'
gem "bson", '~> 2.0.0.rc2'
#gem "bson_ext", '~> 1.8.6'
gem 'mongoid_slug', github: 'nofxx/mongoid-slug'

# Check Daemon
gem 'rufus-lua'

# Background jobs
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'sidekiq'

# API intercommunication
gem 'httparty'