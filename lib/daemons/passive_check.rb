#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do 
  $running = false
end

while($running) do
  
  # Replace this with your code
  Rails.logger.auto_flushing = true
  Check.where(updated_at: {"$lte" => DateTime.now - Settings.max_silence.seconds}) do |check|
    check.soft_status = false
    check.hard_status = false
    check.save
  end

  Rails.logger.info "This daemon is still running at #{Time.now}.\n"
  
  sleep 10
end
