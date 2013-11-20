class V1::ClustersController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /v1/users/:user_id/domains/:domain_id/clusters/
  # Return all clusters of Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # Return:
  # - an array of user's clusters if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      @clusters=@domain.clusters

      respond_to do |format|
        format.html {render text: @clusters.to_json}
        format.xml {render xml: @clusters}
        format.json {render json: @clusters}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== POST: /v1/users/:user_id/domains/:domain_id/clusters/
  # Create a new cluster in Domain; autocreate the default region
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - type: the cluster type (one of HA,LB,GEO)
  # - name: The name of record
  # - check: the nagios plugin script to call, empty for ping
  # - check_args: the nagios plugin parameters
  # - enabled: if this record is active or not
  # Return:
  # - an array of default zone record data if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      @cluster=@domain.clusters.create!(:type => params[:type].upcase, :name => params[:name], :check => params[:check], :check_args => params[:check_args], :enabled => enabled?(params[:enabled]))
      @cluster_geo=@cluster.geo_locations.create!(:region => 'default')

      respond_to do |format|
        format.html {render text: @cluster_geo.to_json}
        format.xml {render xml: @cluster_geo}
        format.json {render json: @cluster_geo}
      end

    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== PUT: /v1/users/:user_id/domains/:domain_id/clusters/:id
  # Update a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # - type: the cluster type (one of HA,LB,GEO)
  # - name: The name of record
  # - check: the nagios plugin script to call, empty for ping
  # - check_args: the nagios plugin parameters
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      @cluster=@domain.clusters.find(params[:id])
      @cluster.update_attributes!(:type => params[:type].upcase, :name => params[:name], :check => params[:check], :check_args => params[:check_args], :enabled => enabled?(params[:enabled]))

      respond_to do |format|
        format.html {render text: @cluster.to_json}
        format.xml {render xml: @cluster}
        format.json {render json: @cluster}
      end

    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== DELETE: /v1/users/:user_id/domains/:domain_id/clusters/:id
  # Delete a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the rcluster
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      @cluster=@domain.clusters.find(params[:id])
      @cluster.destroy

      respond_to do |format|
        format.html {render text: @cluster.to_json}
        format.xml {render xml: @cluster}
        format.json {render json: @cluster}
      end

    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== GET: /v1/users/:user_id/domains/:domain_id/clusters/:id
  # Show a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the cluster
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def show
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      @cluster=@domain.clusters.find(params[:id])
      respond_to do |format|
        format.html {render text: @cluster.to_json}
        format.xml {render xml: @cluster}
        format.json {render json: @cluster}
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
