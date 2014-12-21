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


class V1::NeighborsController < ApplicationController
  before_filter :restrict_access, :is_admin

  # ==== GET: /v1/regions/:region_id/neighbors
  #
  # Params:
  # - key: the admin key
  # - password: the admin password
  # - region_id: the id of this region
  # Return all regions neighbor of selected region
  #
  # Return:
  # - an array of regions if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    region = Region.find(params[:region_id])
    render json: region.neighbor_regions.order_by(:proximity => :asc)
  end

  # ==== GET: /v1/regions/:region_id/neighbors/:id
  #
  # Params:
  # - key: the admin key
  # - password: the admin password
  # - region_id: the id of this region
  # - id of the neighbor
  # Return the specified neighbor of selected region
  #
  # Return:
  # - a neighbor description if success with 200 code
  # - an error string with the error message if error with code 404
  def show
    region = Region.find(params[:region_id])
    render json: region.neighbor_regions.find(params[:id])
  end

  # ==== POST: /v1/regions/:region_id/neighbors
  #
  # Params:
  # - key: the admin key
  # - password: the admin password
  # - region_id: the id of this region
  # - neighbor_region: the id of the region as neighbor
  # - proximity: how this neighbor is close to the region
  # Return the specified neighbor of selected region
  #
  # Return:
  # - a neighbor description if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    region = Region.find(params[:region_id])
    #neighbor_region = Region.find(params[:neighbor_region])
    #neighbor = region.neighbor_regions.create(:neighbor => neighbor_region, :proximity => params[:proximity])
    neighbor = region.neighbor_regions.create(neighbor_params)
    render json: neighbor
  end

  # ==== PUT: /v1/regions/:region_id/neighbors/:id
  #
  # Params:
  # - key: the admin key
  # - password: the admin password
  # - region_id: the id of this region
  # - id: the id of the neighbor
  # - neighbor_region: the id of the region as neighbor
  # - proximity: how this neighbor is close to the region
  # Return the specified neighbor of selected region
  #
  # Return:
  # - the description of updated neighbor if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    neighbor = Region.find(params[:region_id]).neighbor_regions.find(params[:id])
    #neighbor_region = Region.find(params[:neighbor_region])
    #neighbor.update(:neighbor => neighbor_region, :proximity => params[:proximity])
    neighbor.update!(neighbor_params)
    render json: neighbor
  end

  # ==== DELETE: /v1/regions/:region_id/neighbors/:id
  #
  # Params:
  # - key: the admin key
  # - password: the admin password
  # - region_id: the id of this region
  # - id: the id of the neighbor
  # Return the specified neighbor of selected region
  #
  # Return:
  # - the description of deleted neighbor if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    neighbor = Region.find(params[:region_id]).neighbor_regions.find(params[:id])
    neighbor.destroy
    render json: neighbor
  end

  private

  def neighbor_params
    params.require(:neighbor).permit(:proximity, :neighbor_region)
  end
end
