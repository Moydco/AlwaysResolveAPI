class V1::GeoLocationsController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /v1/users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/
  # Return all GeoLocation in Cluster
  #
  # Params:
  # - user_id: the id of the User
  # - domain_id: the id of the Domain
  # - cluster_id: the id of the Cluster
  # Return:
  # - an array of cluster geo_locations if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    begin
      @user = User.find(params[:user_id])
      @cluster = @user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id])
      @geo_locations=@cluster.geo_locations

      render json: @geo_locations
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== POST: /v1/users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/
  # Create a new GeoLocation in Cluster
  # Please always create a geo_loaction named "default" for non geolocalized records
  #
  # Params:
  # - user_id: the id of the User
  # - domain_id: the id of the Domain
  # - cluster_id: the id of the Cluster
  # - region: the region
  # Return:
  # - an array of geo location data if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      @cluster = @user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id])
      @geo_location=@cluster.geo_locations.create!(:region => params[:region])

      render json: @geo_location

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== PUT: /v1/users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:id
  # Update a GeoLocation in Cluster
  #
  # Params:
  # - user_id: the id of the User
  # - domain_id: the id of the Domain
  # - cluster_id: the id of the Cluster
  # - id: the id of the GeoLocation
  # - region: the region
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      @user = User.find(params[:user_id])
      @geo_location=@user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id]).geo_locations.find(params[:id])
      unless @geo_location.region == 'default'
        @geo_location.update_attributes!(:region => params[:region])

        render json: @geo_location
      else
        render json: {error: "Can't update default region"}, status: 404
      end
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== DELETE: /v1/users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:id
  # Delete a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - cluster_id: the id of the Cluster
  # - id: the id of the GeoLocation
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    begin
      @user = User.find(params[:user_id])
      @geo_location=@user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id]).geo_locations.find(params[:id])
      unless @geo_location.region == 'default'
        @geo_location.destroy

        render json: @geo_location
      else
        render json: {error: "Can't delete default region"}, status: 404
      end

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== GET: /v1/users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:id
  # Show a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - cluster_id: the id of the Cluster
  # - id: the id of the GeoLocation
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def show
    begin
      @user = User.find(params[:user_id])
      @geo_location=@user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id]).geo_locations.find(params[:id])
      render json: @geo_location

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

end
