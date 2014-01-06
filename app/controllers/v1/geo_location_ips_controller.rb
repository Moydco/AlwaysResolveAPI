class V1::GeoLocationIpsController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /v1/users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:geo_location_id/geo_location_ips/
  # Return all records of a GeoLocation zone
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - cluster_id: the id of the Cluster
  # - geo_location_id: the id of the GeoLocation
  # - type: the record type (one of A,AAAA), empty for all
  # Return:
  # - an array of user's record if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    begin
      @user = User.find(params[:user_id])
      @geo_location=@user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id]).geo_locations.find(params[:geo_location_id])
      if !params[:type].nil? and params[:type].upcase == 'A'
        @records=@geo_location.a_records
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @records=@geo_location.aaaa_records
      else
        @records={ a: @geo_location.a_records,
                   aaaa: @geo_location.aaaa_records
        }
      end
      render json: @records
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== POST: /v1/users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:geo_location_id/geo_location_ips/
  # Create a new record in a GeoLocation zone
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - cluster_id: the id of the Cluster
  # - geo_location_id: the id of the GeoLocation
  # - type: the record type (one of A,AAAA)
  # - ip: the ip address that resolve to (for A and AAAA records)
  # - priority: the priority for resolution if the cluster type is HA else ignored
  # - weight: the weight for resolution if the cluster type is LB else ignored
  # - enabled: if this record is active or not
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      @user = User.find(params[:user_id])
      @cluster=@user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id])
      @geo_location=@cluster.geo_locations.find(params[:geo_location_id])
      if params[:weight].nil?
        weight=1
      else
        weight=params[:weight]
      end
      if params[:priority].nil?
        priority=1
      else
        priority=params[:priority]
      end

      if !params[:type].nil? and params[:type].upcase == 'A'
        @record=@geo_location.a_records.create!(:name => @cluster.name, :ip => params[:ip], :priority => priority, :weight => weight, :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @record=@geo_location.aaaa_records.create!(:name => @cluster.name, :ip => params[:ip], :priority => priority, :weight => weight, :enabled => enabled?(params[:enabled]))
      else
        @record=nil
      end
      unless @record.nil?
        render json: @record
      else
        render json: {error: "Unknown type"}, status: 404
      end

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== PUT: /v1/users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:geo_location_id/geo_location_ips/:id/
  # Update a record of a GeoLocation zone
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - cluster_id: the id of the Cluster
  # - geo_location_id: the id of the GeoLocation
  # - id: the id of the record
  # - type: the record type (one of NS,A,AAAA,CNAME,MX,TXT, SOA)
  # - ip: the ip address that resolve to (for A and AAAA records)
  # - priority: the priority for resolution if the cluster type is HA else ignored
  # - weight: the weight for resolution if the cluster type is LB, else ignored
  # - enabled: if this record is active or not
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      @user = User.find(params[:user_id])
      @cluster=@user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id])
      @geo_location=@cluster.geo_locations.find(params[:geo_location_id])
      if params[:weight].nil?
        weight=1
      else
        weight=params[:weight]
      end
      if params[:priority].nil?
        priority=1
      else
        priority=params[:priority]
      end
      if !params[:type].nil? and params[:type].upcase == 'A'
        @record=@geo_location.a_records.find(params[:id])
        @record.update_attributes!(:name => @cluster.name, :ip => params[:ip], :priority => priority, :weight => weight, :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @record=@geo_location.aaaa_records.find(params[:id])
        @record.update_attributes!(:name => @cluster.name, :ip => params[:ip], :priority => priority, :weight => weight, :enabled => enabled?(params[:enabled]))
      else
        @record=nil
      end
      unless @record.nil?
        render json: @record
      else
        render json: {error: "Unknown type"}, status: 404
      end

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== DELETE: /v1/users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:geo_location_id/geo_location_ips/:id/
  # Delete a record of a GeoLocation zone
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - cluster_id: the id of the Cluster
  # - geo_location_id: the id of the GeoLocation
  # - id: the id of the record
  # - type: the record type (one of A,AAAA)
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    begin
      @user = User.find(params[:user_id])
      @geo_location=@user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id]).geo_locations.find(params[:geo_location_id])
      if !params[:type].nil? and params[:type].upcase == 'A'
        @record=@geo_location.a_records.find(params[:id])
        @record.destroy
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @record=@geo_location.aaaa_records.find(params[:id])
        @record.destroy
      else
        @record=nil
      end
      unless @record.nil?
        render json: @record
      else
        render json: {error: "Unknown type"}, status: 404
      end

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== GET: /v1/users/:user_id/domains/:domain_id/clusters/:cluster_id/geo_locations/:geo_location_id/geo_location_ips/:id/
  # Show a record of a GeoLocation zone
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - cluster_id: the id of the Cluster
  # - geo_location_id: the id of the GeoLocation
  # - id: the id of the record
  # - type: the record type (one of A,AAAA)
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def show
    begin
      @user = User.find(params[:user_id])
      @geo_location=@user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id]).geo_locations.find(params[:geo_location_id])
      if !params[:type].nil? and params[:type].upcase == 'A'
        @record=@geo_location.a_records.find(params[:id])
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @record=@geo_location.aaaa_records.find(params[:id])
      else
        @record=nil
      end
      unless @record.nil?
        render json: @record
      else
        render json: {error: "Unknown type"}, status: 404
      end

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end
end
