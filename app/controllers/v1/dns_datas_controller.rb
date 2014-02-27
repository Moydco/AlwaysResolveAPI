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
    Cluster.where(:enabled => true).each do |cluster|
      cluster.geo_locations.each do |region|
        region.a_records.each do |host|
          conf.push(
              {
                  :reference => host.id.to_s,
                  :ip_address => host.ip,
                  :check => cluster.check,
                  :check_args => cluster.check_args,
                  :enabled => cluster.enabled.to_s
              }
          )
        end
      end
    end

    render json: conf

  end
end
