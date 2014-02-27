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
  # - zone: the zone name of Domain (ex. example.org)
  # Return:
  # - an array of user's domain created if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.create!(:zone => params[:zone])
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
  # - zone: the zone name of domain (ex. example.org)
  # Return:
  # - an array of user's domain modified if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:id])
      @domain.update_attributes(:zone => params[:zone])
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
end
