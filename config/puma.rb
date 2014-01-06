rails_env = ENV['RAILS_ENV'] || 'development'

threads 4,4

bind  "unix:///tmp/api.moyd.co-puma.sock"
pidfile "/tmp/api.moyd.co-puma.pid"
state_path "/tmp/api.moyd.co-puma.state"

activate_control_app