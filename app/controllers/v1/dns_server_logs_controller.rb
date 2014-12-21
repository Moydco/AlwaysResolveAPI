# --------------------------------------------------------------------------- #
# Copyright 2013-2015, AlwaysResolve Project (alwaysresolve.org), MOYD.CO LTD #
#                                                                             #
# Licensed under the Apache License, Version 2.0 (the "License"); you may     #
# not use this file except in compliance with the License. You may obtain     #
# a copy of the License at                                                    #
#                                                                             #
# http://www.apache.org/licenses/LICENSE-2.0                                  #
#                                                                             #
# Unless required by applicable law or agreed to in writing, software         #
# distributed under the License is distributed on an "AS IS" BASIS,           #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    #
# See the License for the specific language governing permissions and         #
# limitations under the License.                                              #
# --------------------------------------------------------------------------- #


class V1::DnsServerLogsController < ApplicationController
  before_filter :restrict_access, :is_admin

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
    events = nil
    region = Region.find(params[:region_id])
    if params[:server].nil? or params[:server].blank?
      region.server_logs.all
    else
      events = region.server_logs.where(:server => params[:server])
    end

    render json: events
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
    event = region.server_logs.create!(:server => params[:server], :signal => params[:signal].upcase, :log => params[:log])

    render json: event
  end
end
