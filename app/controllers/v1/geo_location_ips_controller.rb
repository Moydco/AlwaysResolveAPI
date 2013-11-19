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
      respond_to do |format|
        format.html {render text: @records.to_json}
        format.xml {render xml: @records}
        format.json {render json: @records}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
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
  # - enabled: if this record is active or not
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      @user = User.find(params[:user_id])
      @cluster=@user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id])
      @geo_location=@cluster.geo_locations.find(params[:geo_location_id])
      if !params[:type].nil? and params[:type].upcase == 'A'
        @record=@geo_location.a_records.create!(:name => @cluster.name, :ip => params[:ip], :priority => params[:priority], :enabled => params[:enabled])
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @record=@geo_location.aaaa_records.create!(:name => @cluster.name, :ip => params[:ip], :priority => params[:priority], :enabled => params[:enabled])
      else
        @record=nil
      end
      unless @record.nil?
        respond_to do |format|
          format.html {render text: @record.to_json}
          format.xml {render xml: @record}
          format.json {render json: @record}
        end
      else
        respond_to do |format|
          format.html {render text: "Unknown type" }
          format.xml {render xml: {error: "Unknown type"}, status: 404 }
          format.json {render json: {error: "Unknown type"}, status: 404 }
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
  # - enabled: if this record is active or not
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      @user = User.find(params[:user_id])
      @cluster=@user.domains.find(params[:domain_id]).clusters.find(params[:cluster_id])
      @geo_location=@cluster.geo_locations.find(params[:geo_location_id])
      if !params[:type].nil? and params[:type].upcase == 'A'
        @record=@geo_location.a_records.find(params[:id])
        @record.update_attributes!(:name => @cluster.name, :ip => params[:ip], :priority => params[:priority], :enabled => params[:enabled])
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @record=@geo_location.aaaa_records.find(params[:id])
        @record.update_attributes!(:name => @cluster.name, :ip => params[:ip], :priority => params[:priority], :enabled => params[:enabled])
      else
        @record=nil
      end
      unless @record.nil?
        respond_to do |format|
          format.html {render text: @record.to_json}
          format.xml {render xml: @record}
          format.json {render json: @record}
        end
      else
        respond_to do |format|
          format.html {render text: "Unknown type" }
          format.xml {render xml: {error: "Unknown type"}, status: 404 }
          format.json {render json: {error: "Unknown type"}, status: 404 }
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
        respond_to do |format|
          format.html {render text: @record.to_json}
          format.xml {render xml: @record}
          format.json {render json: @record}
        end
      else
        respond_to do |format|
          format.html {render text: "Unknown type" }
          format.xml {render xml: {error: "Unknown type"}, status: 404 }
          format.json {render json: {error: "Unknown type"}, status: 404 }
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
        respond_to do |format|
          format.html {render text: @record.to_json}
          format.xml {render xml: @record}
          format.json {render json: @record}
        end
      else
        respond_to do |format|
          format.html {render text: "Unknown type" }
          format.xml {render xml: {error: "Unknown type"}, status: 404 }
          format.json {render json: {error: "Unknown type"}, status: 404 }
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
end
