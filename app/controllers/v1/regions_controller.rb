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


class V1::RegionsController < ApplicationController
  before_filter :restrict_access, :is_admin

  # ==== GET: /v1/regions/
  #
  # Params:
  # - key: the admin key
  # - password: the admin password
  # Return all regions
  #
  # Return:
  # - an array of regions if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    render json: Region.all
  end

  # ==== GET: /v1/regions/:id
  # Return a regions
  #
  # Params:
  # - id: the id of the region
  # - key: the admin key
  # - password: the admin password
  # Return:
  # - an array describe selected region if success with 200 code
  # - an error string with the error message if error with code 404
  def show
    render json: Region.find(params[:id])
  end

  # ==== POST: /v1/regions/
  # Create a region
  #
  # Params:
  # - region => code: String, two-letters country code (ex. IT, US)
  # - region => dns_ip_address: String, the ip address of local RabbitMQ server
  # - region => check_ip_address: String, the ip address of local Check server
  # - region => has_dns: Boolean, if there is a DNS server
  # - region => has_check: Boolean, if there is a check server
  # - key: the admin key
  # - password: the admin password
  # Return:
  # - an array describe created region if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    region = Region.create(region_params)
    render json: region
  end

  # ==== PUT: /v1/regions/:id
  # Update a region
  #
  # Params:
  # - id: the id of the region
  # - region => code: String, two-letters country code (ex. IT, US)
  # - region => dns_ip_address: String, the ip address of local RabbitMQ server
  # - region => check_ip_address: String, the ip address of local Check server
  # - region => has_dns: Boolean, if there is a DNS server
  # - region => has_check: Boolean, if there is a check server
  # - key: the admin key
  # - password: the admin password
  # Return:
  # - an array describe updated region if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    region = Region.find(params[:id])
    region.update!(region_params)
    render json: region
  end

  # ==== DELETE: /v1/regions/:id
  # Destroy a region
  #
  # Params:
  # - id: the id of the region
  # - key: the admin key
  # - password: the admin password
  # Return:
  # - an array describe deleted region if success with 200 code
  # - an error string with the error message if error with code 404
  def
  destroy
    region = Region.find(params[:id])
    region.destroy
    render json: region
  end

  private

  def region_params
    params.require(:region).permit(
        :country_code,
        :code,
        :dns_ip_address,
        :check_ip_address,
        :has_check,
        :has_dns
    )
  end
end
