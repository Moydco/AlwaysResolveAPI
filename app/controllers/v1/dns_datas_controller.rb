class V1::DnsDatasController < ApplicationController
  before_filter :restrict_access

  def index
    domains = ''
    Domain.each do |d|
      domains += d.zone
      domains += ' '
    end
    render text: domains
  end

  def show
    domain = Domain.where(:zone => params[:zone]).first
    render text: domain.json_zone(params[:region]) unless domain.nil?
  end

  def check_list
    conf = []
    # Load cluster configurations
    Cluster.where(:enabled => true).each do |cluster|
      cluster.geo_locations.each do |region|
        region.a_records.each do |host|
          conf.push(
              {
                  :reference => "#{cluster.check.id.to_s}-#{host.id.to_s}",
                  :ip_address => host.ip,
                  :check => cluster.check.check,
                  :check_args => cluster.check.check_args,
                  :enabled => cluster.check.enabled.to_s
              }
          )
        end
      end
    end

    # Load A Record configurations
    ARecord.where(:enabled => true, ).each do |host|
      unless host.check.nil?
          conf.push(
              {
                  :reference => "#{host.check.id.to_s}-#{host.id.to_s}",
                  :ip_address => host.ip,
                  :check => host.check.check,
                  :check_args => host.check.check_args,
                  :enabled => host.check.enabled.to_s
              }
          )
      end
    end
    render json: conf

  end

  def update_from_check

  end
end

