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


class V1::DomainsController < ApplicationController
  before_filter :restrict_access

  before_filter :authorize_resource

  # ==== GET: /v1/users/:user_id/domains
  # Return all domains ownded by User
  #
  # Params:
  # - user_id: the id of the user
  # Return:
  # - an array of user's domains if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    begin
      @user = User.find(params[:user_id])
      @domains = @user.domains
      render json: @domains
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== GET: /v1/users/:user_id/domains/:id
  # Show domain details
  #
  # Params:
  # - user_id: the id of the User
  # - id: the id of Domain
  # Return:
  # - an array of user's domain details if success with 200 code
  # - an error string with the error message if error with code 404
  def show
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:id])
      render json: @domain
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== POST: /v1/users/:user_id/domains
  # Show domain details
  #
  # Params:
  # - user_id: the id of the User
  # - domain => zone: the zone name of domain (ex. example.org)
  # - domain => ttl: the zone default ttl
  # Return:
  # - an array of user's domain created if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.create!(domain_params)
      render json: @domain
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== PUT: /v1/users/:user_id/domains/:id
  # Show domain details
  #
  # Params:
  # - user_id: the id of the User
  # - id: the id of the Domain
  # - domain => zone: the zone name of domain (ex. example.org)
  # - domain => ttl: the zone default ttl
  # Return:
  # - an array of user's domain modified if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:id])
      @domain.update!(domain_params)
      render json: @domain
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== DELETE: /v1/users/:user_id/domains/:id
  # Show domain details
  #
  # Params:
  # - user_id: the id of the User
  # - id: the id of the Domain
  # Return:
  # - an array of user's domain deleted if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:id])
      if @domain.destroy
        render json: @domain
      else
        render json: {error: "Error deleting domain"}, status: 404
      end
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== GET: /v1/users/:user_id/domains/:id/monthly_total
  # Show monthly total domain queries
  #
  # Params:
  # - user_id: the id of the User
  # - id: the id of the Domain
  # - month: the month (01..12)
  # - year: the year (2014..)
  # Return:
  # - an array of user's domain deleted if success with 200 code
  # - an error string with the error message if error with code 404
  def monthly_total
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:id])
      render json: @domain.domain_monthly_stats.where(month: params[:month], year: params[:year]).first.to_json

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== GET: /v1/users/:user_id/domains/:id/daily_stat
  # Show daily detail domain queries
  #
  # Params:
  # - user_id: the id of the User
  # - id: the id of the Domain
  # - day: the day (01..31)
  # - month: the month (01..12)
  # - year: the year (2014..)
  # Return:
  # - an array of user's domain deleted if success with 200 code
  # - an error string with the error message if error with code 404
  def daily_stat
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:id])
      render json: @domain.domain_statistics.where(:created_at.gte => params[:year]+'-'+params[:month]+'-'+params[:day],
                                                   :created_at.lt => params[:year]+'-'+params[:month]+'-'+ (params[:day].to_i+1).to_s )

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== GET: /v1/users/:user_id/domains/:id/bind_zone
  # Show daily detail domain queries
  #
  # Params:
  # - user_id: the id of the User
  # - id: the id of the Domain
  # - region_id: the id of the region
  # Return:
  # - a txt with the zone in bind format
  # - an error string with the error message if error with code 404
  def bind_zone
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:id])
      render txt: @domain.bind_zone(params[:region_id])

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  private

  def domain_params
    params.require(:domain).permit(:zone, :ttl)
  end
end
