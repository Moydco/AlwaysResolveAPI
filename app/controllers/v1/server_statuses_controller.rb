class V1::ServerStatusesController < ApplicationController
  before_filter :check_admin

  # ==== POST: /v1/regions/:region_id/server_statuses
  # Update heartbeat of a server
  #
  # Params:
  # - key: the admin key
  # - password: the admin password
  # - region_id: the id of datacenter region
  # - server: the DNS server id in region
  # Return:
  # - an array with updated heartbeat data
  def create
    region = Region.find(params[:region_id])
    dns = region.server_statuses.where(:server => params[:server]).first
    if dns.nil?
      dns = region.server_statuses.create(:server => params[:server])
    else
      dns.touch
    end
    respond_to do |format|
      format.html {render text: dns.to_json}
      format.xml {render xml: dns}
      format.json {render json: dns}
    end
  end

  # ==== GET: /v1/regions/:region_id/server_statuses
  # Return a the last seen heartbeat of a server
  #
  # Params:
  # - key: the admin key
  # - password: the admin password
  # - region_id: the id of datacenter region
  # - server: the DNS server id in region
  # Return:
  # - an array with last seen heartbeat data
  def index
    region = Region.find(params[:region_id])
    dns = region.server_statuses.where(:server => params[:server]).first

    respond_to do |format|
      format.html {render text: dns.to_json}
      format.xml {render xml: dns}
      format.json {render json: dns}
    end

  end
end
