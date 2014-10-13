class V1::RecordsController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /v1/users/:user_id/domains/:domain_id/records/
  # Return all records of Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # Return:
  # - an array of user's record if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    begin
      records = User.find(params[:user_id]).domains.find(params[:domain_id]).records.all

      render json: records.to_json(:include => :answers)
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== POST: /v1/users/:user_id/domains/:domain_id/records/
  # Create a new record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - record => type: the record type (one of NS,A,AAAA,CNAME,MX,TXT)
  # - record => name: The name of record
  # - record => ttl: The ttl of record (optional, default 60)
  # - record => routing_policy, the routing policy (one of SIMPLE WEIGHTED LATENCY FAILOVER), default SIMPLE
  # - record => set_id, a mnemonic identificator, only for WEIGHTED LATENCY FAILOVER routing policy
  # - record => weight, only if routing_policy is WEIGHTED
  # - record => primary, boolean only if routing_policy is FAILOVER
  # - record => geo_location, Region ID only if routing_policy is LATENCY
  # - record => alias, boolean if this is an internal alias of another record (internal CNAME)
  # - record => enabled: if this record is active or not
  # - record => answers_attributes => ip: the ip address that resolve to (for PTR, A and AAAA records)
  # - record => answers_attributes => data: the value that resolve to  (for CNAME, MX, NS, PTR, SRV, TXT)
  # - record => answers_attributes => priority: the priority (for MX, SRV)
  # - record => answers_attributes => weight: the weight (for SRV)
  # - record => answers_attributes => port: the port (for SRV)
  # - record => answers_attributes => mname: the primary DNS (for SOA)
  # - record => answers_attributes => rname: the email (for SOA)
  # - record => answers_attributes => at: the SOA TTL (for SOA)
  # - record => answers_attributes => refresh: the refresh (for SOA)
  # - record => answers_attributes => retry: the retry (for SOA)
  # - record => answers_attributes => expire: the expire (for SOA)
  # - record => answers_attributes => minimum: the minimum (for SOA)
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      domain = User.find(params[:user_id]).domains.find(params[:domain_id])
      record=domain.records.create!(record_params)

      unless record.nil?
        render json: record.to_json(:include => :answers)
      else
        render json: {error: "Unknown type"}, status: 404
      end

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== PUT: /v1/users/:user_id/domains/:domain_id/records/:id
  # Update a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # - record => type: the record type (one of NS,A,AAAA,CNAME,MX,TXT)
  # - record => name: The name of record
  # - record => ttl: The ttl of record (optional, default 60)
  # - record => routing_policy, the routing policy (one of SIMPLE WEIGHTED LATENCY FAILOVER)
  # - record => set_id, a mnemonic identificator
  # - record => weight, only if routing_policy is WEIGHTED
  # - record => primary, boolean only if routing_policy is FAILOVER
  # - record => geo_location, Region ID only if routing_policy is LATENCY
  # - record => alias, boolean if this is an internal alias of another record (internal CNAME)
  # - record => enabled: if this record is active or not
  # - record => answers_attributes => id: the id of the answer to update, empty for adding one
  # - record => answers_attributes => _destroy: if the id is not empty, set to '1' to delete the answer
  # - record => answers_attributes => ip: the ip address that resolve to (for PTR, A and AAAA records)
  # - record => answers_attributes => data: the value that resolve to  (for CNAME, MX, NS, PTR, SRV, TXT)
  # - record => answers_attributes => priority: the priority (for MX, SRV)
  # - record => answers_attributes => weight: the weight (for SRV)
  # - record => answers_attributes => port: the port (for SRV)
  # - record => answers_attributes => mname: the primary DNS (for SOA)
  # - record => answers_attributes => rname: the email (for SOA)
  # - record => answers_attributes => at: the SOA TTL (for SOA)
  # - record => answers_attributes => refresh: the refresh (for SOA)
  # - record => answers_attributes => retry: the retry (for SOA)
  # - record => answers_attributes => expire: the expire (for SOA)
  # - record => answers_attributes => minimum: the minimum (for SOA)
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      record = User.find(params[:user_id]).domains.find(params[:domain_id]).records.find(params[:id])

      unless record.nil?
        record.update!(record_params)
        render json: record.to_json(:include => :answers)
      else
        render json: {error: "Unknown type"}, status: 404
      end

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== DELETE: /v1/users/:user_id/domains/:domain_id/records/:id
  # Delete a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    begin
      domain = User.find(params[:user_id]).domains.find(params[:domain_id])
      record = domain.records.find(params[:id])
      domain.update_zone

      unless record.nil?
        record.destroy
        render json: record.to_json(:include => :answers)
      else
        render json: {error: "Unknown type"}, status: 404
      end

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== GET: /v1/users/:user_id/domains/:domain_id/records/:id
  # Show a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # - type: the record type (one of NS,A,AAAA,CNAME,MX,TXT, SOA)
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def show

    begin
      record = User.find(params[:user_id]).domains.find(params[:domain_id]).records.find(params[:id])
      render json: record.to_json(:include => :answers)

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== PUT:  /v1/users/:user_id/domains/:domain_id/records/:id/update_link
  # Update the record linked with the service
  #
  # Params:
  # - user_id: the id of the user
  # - id: the id of the check
  # - check_id: the ID of check linked to the record
  # Return:
  # - a description of the record if success with 200 code
  # - an error string with the error message if error with code 404
  def update_link
    begin
      user = User.find(params[:user_id])
      if params[:check_id].nil? or params[:check_id].blank?
        check=nil
      else
        check = user.checks.find(psarams[:check_id])
      end

      linked_service = user.domains.find(params[:domain_id]).records.find(params[:id])
      linked_service.check = check
      linked_service.save

      render json: linked_service
    rescue => e
      render json: {error: "#{e.message}"}, status: 404

    end
  end

  # ==== GET: /v1/users/:user_id/domains/:domain_id/records/:id/old_versions
  # Show old record version
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def old_versions
    begin
      record = User.find(params[:user_id]).domains.find(params[:domain_id]).records.find(params[:id])
      render json: record.versions.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== PUT: /v1/users/:user_id/domains/:domain_id/records/:id/redo_version
  # Show a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # - redo_id: the ID of version to redeem
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def redo_version
    begin
      record = User.find(params[:user_id]).domains.find(params[:domain_id]).records.find(params[:id])

      unless record.nil?
        redo_version = record.versions.find(params[:redo_id])
        record.revert! redo_version.version unless redo_version.nil?
        render json: record.to_json(:include => :answers)
      else
        render json: {error: "Unknown type"}, status: 404
      end

    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== PUT: /v1/users/:user_id/domains/:domain_id/records/:id/trash
  # Trash a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def trash
    begin
      record = User.find(params[:user_id]).domains.find(params[:domain_id]).records.find(params[:id])
      record.update_attribute(:trashed, true) unless record.nil?
      render json: record.to_json(:include => :answers)
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== PUT: /v1/users/:user_id/domains/:domain_id/records/:id/untrash
  # Undo last update
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def undo
    begin
      record = User.find(params[:user_id]).domains.find(params[:domain_id]).records.find(params[:id])
      record.revert!
      render json: record.to_json(:include => :answers)
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end


  # ==== PUT: /v1/users/:user_id/domains/:domain_id/records/:id/undo
  # Show a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def untrash
    begin
      record = User.find(params[:user_id]).domains.find(params[:domain_id]).records.find(params[:id])
      record.update_attribute(:trashed, false) unless record.nil?
      render json: record.to_json(:include => :answers)
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== POST: /v1/users/:user_id/domains/:domain_id/records/empty_trash
  # Destroy all trashed records
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def empty_trash
    begin
      User.find(params[:user_id]).domains.find(params[:domain_id]).records.where(trashed: true).each do |record|
        record.destroy
      end

      records = User.find(params[:user_id]).domains.find(params[:domain_id]).records.all

      render json: records.to_json(:include => :answers)
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  def record_params
    params.require(:record).permit(
        :name,
        :type,
        :ttl,
        :routing_policy,
        :set_id,
        :weight,
        :primary,
        :alias,
        :enabled,
        :geo_location,
        :answers_attributes => [
            :ip,
            :data,
            :priority,
            :mname,
            :rname,
            :at,
            :refresh,
            :retry,
            :expire,
            :minimum,
            :weight,
            :port,
            :id,
            :algorithm,
            :typeCovered,
            :labels,
            :originalTTL,
            :signatureExpiration,
            :signatureInception,
            :keyTag,
            :signerName,
            :signature,
            :flags,
            :protocol,
            :publicKey,
            :_destroy
        ]
    )
  end
end
