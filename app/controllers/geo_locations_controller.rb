class GeoLocationsController < ApplicationController

  # ==== GET: /users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/
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

      respond_to do |format|
        format.html {render text: @geo_locations}
        format.xml {render xml: @geo_locations}
        format.json {render json: @geo_locations}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== POST: /users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/
  # Create a new GeoLocation in Cluster
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

      respond_to do |format|
        format.html {render text: @geo_location}
        format.xml {render xml: @geo_location}
        format.json {render json: @geo_location}
      end

    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== PUT: /users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:id
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

        respond_to do |format|
          format.html {render text: @geo_location}
          format.xml {render xml: @geo_location}
          format.json {render json: @geo_location}
        end
      else
        respond_to do |format|
          format.html {render text: "Can't update default region" }
          format.xml {render xml: {error: "Can't update default region"}, status: 404 }
          format.json {render json: {error: "Can't update default region"}, status: 404 }
        end
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== DELETE: /users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:id
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

        respond_to do |format|
          format.html {render text: @geo_location}
          format.xml {render xml: @geo_location}
          format.json {render json: @geo_location}
        end
      else
        respond_to do |format|
          format.html {render text: "Can't delete default region" }
          format.xml {render xml: {error: "Can't delete default region"}, status: 404 }
          format.json {render json: {error: "Can't delete default region"}, status: 404 }
        end
      end

    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== GET: /users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:id
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
      respond_to do |format|
        format.html {render text: @geo_location}
        format.xml {render xml: @geo_location}
        format.json {render json: @geo_location}
      end

    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

end
