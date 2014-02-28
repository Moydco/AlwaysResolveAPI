Sidekiq.configure_server do |config|
  config.redis = { :url => 'redis://redis-server:6379/12', :namespace => 'api' }
end

Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://redis-server:6379/12', :namespace => 'api' }
end