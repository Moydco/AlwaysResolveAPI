#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"
#ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do 
  $running = false
end

Rails.logger.info "Starting check daemon"


Host.new.initialize_db

while($running) do
  Rails.logger.info "Inside loop..."
  # Replace this with your code
  Host.where(:on_check => false, :enabled => true).each do |host|
    Rails.logger.info "Checking #{host.ip_address} with #{host.check} and #{host.check_args}"
    host.lockService
    CheckWorker.perform_async(host.id.to_s)
  end
  sleep Settings.every
end
