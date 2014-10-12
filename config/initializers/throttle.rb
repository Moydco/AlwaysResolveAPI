# config/initializers/throttle.rb

require "redis"
REDIS = Redis.new(:host => Settings.redis_host, :port => Settings.redis_port)
