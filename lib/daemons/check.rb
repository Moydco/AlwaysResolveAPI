#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do 
  $running = false
end

# Unlock all check of current server in this region or in default region
Cluster.where(:enabled => true) do |cluster|
  if cluster.geo_locations.where(:region => Settings.region).nil?
    cluster.geo_locations.where(:region => Settings.region).first.a_records do |record|
      record.resetLock(Settings.region)
    end
  else
    cluster.geo_locations.where(:region => 'default').first.a_records do |record|
      record.resetLock(Settings.region)
    end
  end
end

while($running) do
  # Select all clusters
  Cluster.where(:enabled => true).each do |cluster|
    Rails.logger.debug "Start check for #{cluster.name + '.' + cluster.domain.zone}.\n"
    Rails.logger.debug "This is a #{cluster.type} cluster.\n"

    if cluster.type == 'HA'
      # is an HA cluster, so I'll check only the record with higher priority
      cluster.geo_locations.where(:region => 'default').first.a_records.order_by(:priority => :asc).limit(1).each do |record|
        Rails.logger.debug "Record #{record.ip} selected.\n"
        if record.enabled == true and !record.on_check?(Settings.region) and (record.last_check.nil? or (record.last_check + (Settings.every).seconds < Time.now))
          Rails.logger.debug "I'll check #{record.ip} host.\n"
          record.lockService(Settings.region)
          if record.check_operational(cluster.check,cluster.check_args)
            Rails.logger.debug "The host #{record.ip} is working.\n"
            record.update_attributes(:operational => true) unless record.operational
          else
            Rails.logger.debug "The host #{record.ip} is not working.\n"
            record.update_attributes(:operational => false) if record.operational
          end
          record.unlockService(Settings.region)
        else
          Rails.logger.debug "I would like to check #{record.ip} host, but it is disabled.\n"
        end
      end

    elsif cluster.type == 'LB'
      # is an LB cluster, so I'll check all records
      cluster.geo_locations.where(:region => 'default').first.a_records.order_by(:priority => :asc).each do |record|
        if record.enabled == true and !record.on_check?(Settings.region) and (record.last_check.nil? or (record.last_check + (Settings.every).seconds < Time.now))
          Rails.logger.debug "I'll check #{record.ip} host.\n"
          record.lockService(Settings.region)
          if record.check_operational(cluster.check,cluster.check_args)
            Rails.logger.debug "The host #{record.ip} is working.\n"
            record.update_attributes(:operational => true) unless record.operational
          else
            Rails.logger.debug "The host #{record.ip} is not working.\n"
            record.update_attributes(:operational => false) if record.operational
          end
          record.unlockService(Settings.region)
        else
          Rails.logger.debug "I would like to check #{record.ip} host, but it is disabled.\n"
        end
      end


    elsif cluster.type == 'GEO'
      # is an Geo cluster, so I'll check all records inside my zone
      if cluster.geo_locations.where(:region => Settings.region).nil?
        cluster.geo_locations.where(:region => Settings.region).first.a_records.order_by(:priority => :asc).each do |record|
          if record.enabled == true and !record.on_check?(Settings.region) and (record.last_check.nil? or (record.last_check + (Settings.every).seconds < Time.now))
            Rails.logger.debug "I'll check #{record.ip} host.\n"
            record.lockService(Settings.region)
            if record.check_operational(cluster.check,cluster.check_args)
              Rails.logger.debug "The host #{record.ip} is working.\n"
              record.update_attributes(:operational => true) unless record.operational
            else
              Rails.logger.debug "The host #{record.ip} is not working.\n"
              record.update_attributes(:operational => false) if record.operational
            end
            record.unlockService(Settings.region)
          else
            Rails.logger.debug "I would like to check #{record.ip} host, but it is disabled.\n"
          end
        end
      end
    else
      cluster.geo_locations.where(:region => 'default').first.a_records.order_by(:priority => :asc).each do |record|
        if record.enabled == true and !record.on_check?(Settings.region) and (record.last_check.nil? or (record.last_check + (Settings.every).seconds < Time.now))
          Rails.logger.debug "I'll check #{record.ip} host.\n"
          record.lockService(Settings.region)
          if record.check_operational(cluster.check,cluster.check_args)
            Rails.logger.debug "The host #{record.ip} is working.\n"
            record.update_attributes(:operational => true) unless record.operational
          else
            Rails.logger.debug "The host #{record.ip} is not working.\n"
            record.update_attributes(:operational => false) if record.operational
          end
          record.unlockService(Settings.region)
        else
          Rails.logger.debug "I would like to check #{record.ip} host, but it is disabled.\n"
        end
      end
    end
  end

  # Rails.logger.auto_flushing = true
  Rails.logger.debug "This daemon is still running at #{Time.now}.\n"
  
  sleep 10
end
