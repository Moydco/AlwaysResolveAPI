class V1::ServerLogsController < ApplicationController
  before_filter :check_admin

  # ==== GET: /v1/regions/:region_id/server_logs
  # Reatun al log events
  #
  # Params:
  # - key: the admin key
  # - password: the admin password
  # - region_id: the id of datacenter region
  # - server: the DNS server id in region (optional)
  # - min_date: starting datetime (optional)
  # - max_date: ending datetime (optional)
  # - paginting: number of records (optional)
  # - paginting: number of records (optional)
  # Return:
  # - an array with requested log data
  def index
    region = Region.find(params[:region_id])
    if params[:server].nil? or params[:server].blank?
      events = region.server_logs.all
    else
      events = region.server_logs.where(:server => params[:server])
    end

    respond_to do |format|
      format.html {render text: events.to_json}
      format.xml {render xml: events}
      format.json {render json: events}
    end
  end

  # ==== POST: /v1/regions/:region_id/server_logs
  # Add a new event for a DNS server
  #
  # Params:
  # - key: the admin key
  # - password: the admin password
  # - region_id: the id of datacenter region
  # - server: the DNS server id in region
  # - event: the event (start,stop)
  # - log: the log stting (optional)
  # Return:
  # - an array with updated heartbeat data
  def create
    region = Region.find(params[:region_id])
  end
end
