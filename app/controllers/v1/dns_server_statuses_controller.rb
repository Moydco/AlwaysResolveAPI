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


class V1::DnsServerStatusesController < ApplicationController
  before_filter :restrict_access, :is_admin

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
    render json: dns
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

    render json: dns

  end
end
