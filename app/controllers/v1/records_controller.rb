class V1::RecordsController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /v1/users/:user_id/domains/:domain_id/records/
  # Return all records of Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - type: the record type (one of SOA,NS,A,AAAA,CNAME,MX,TXT), empty for all
  # Return:
  # - an array of user's record if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      if !params[:type].nil? and params[:type].upcase == 'A'
        @records=@domain.a_records
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @records=@domain.aaaa_records
      elsif !params[:type].nil? and params[:type].upcase == 'CNAME'
        @records=@domain.cname_records
      elsif !params[:type].nil? and params[:type].upcase == 'MX'
        @records=@domain.mx_records
      elsif !params[:type].nil? and params[:type].upcase == 'NS'
        @records=@domain.ns_records
      elsif !params[:type].nil? and params[:type].upcase == 'SOA'
        @records=@domain.soa_record
      elsif !params[:type].nil? and params[:type].upcase == 'TXT'
        @records=@domain.txt_records
      else
        @records={ a: @domain.a_records,
                   aaaa: @domain.aaaa_records,
                   cname: @domain.cname_records,
                   mx: @domain.mx_records,
                   ns: @domain.ns_records,
                   soa: @domain.soa_record,
                   txt: @domain.txt_records
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

  # ==== POST: /v1/users/:user_id/domains/:domain_id/records/
  # Create a new record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - type: the record type (one of NS,A,AAAA,CNAME,MX,TXT)
  # - name: The name of record
  # - ip: the ip address that resolve to (for A and AAAA records)
  # - value: the value that resolve to  (for NS, CNAME, MX, TXT)
  # - enabled: if this record is active or not
  # - priority: the priority (for MX)
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      if !params[:type].nil? and params[:type].upcase == 'A'
        @record=@domain.a_records.create!(:name => params[:name], :ip => params[:ip], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @record=@domain.aaaa_records.create!(:name => params[:name], :ip => params[:ip], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'CNAME'
        @record=@domain.cname_records.create!(:name => params[:name], :value => params[:value], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'MX'
        @record=@domain.mx_records.create!(:name => params[:name], :value => params[:value], :priority => params[:priority], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'NS'
        @record=@domain.ns_records.create!(:name => params[:name], :value => params[:value], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'PTR'
        @record=@domain.ns_records.create!(:ip => params[:ip], :value => params[:value], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'TXT'
        @record=@domain.txt_records.create!(:name => params[:name], :value => params[:value], :enabled => enabled?(params[:enabled]))
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

  # ==== PUT: /v1/users/:user_id/domains/:domain_id/records/:id
  # Update a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # - type: the record type (one of NS,A,AAAA,CNAME,MX,TXT, SOA)
  # - name: The name of record (no for soa)
  # - ip: the ip address that resolve to (for A and AAAA records)
  # - value: the value that resolve to  (for NS, CNAME, MX, TXT)
  # - enabled: if this record is active or not
  # - priority: the priority (for MX)
  # - for SOA parameters see SoaRecord
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      if !params[:type].nil? and params[:type].upcase == 'A'
        @record=@domain.a_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :ip => params[:ip], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @record=@domain.aaaa_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :ip => params[:ip], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'CNAME'
        @record=@domain.cname_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :value => params[:value], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'MX'
        @record=@domain.mx_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :value => params[:value], :priority => params[:priority], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'NS'
        @record=@domain.ns_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :value => params[:value], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'PTR'
        @record=@domain.txt_records.find(params[:id])
        @record.update_attributes!(:ip => params[:ip], :value => params[:value], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'TXT'
        @record=@domain.txt_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :value => params[:value], :enabled => enabled?(params[:enabled]))
      elsif !params[:type].nil? and params[:type].upcase == 'SOA'
        @record=@domain.soa_record.find(params[:id])
        @record.update_attributes!(:mname => params[:mname], :rname => params[:rname], :at => params[:at], :refresh => params[:resfresh], :retry => params[:retry], :expire => params[:expire], :minimum => params[:minimum])
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

  # ==== DELETE: /v1/users/:user_id/domains/:domain_id/records/:id
  # Delete a record in Domain
  #
  # Params:
  # - user_id: the id of the user
  # - domain_id: the id of the domain
  # - id: the id of the record
  # - type: the record type (one of NS,A,AAAA,CNAME,MX,TXT, SOA)
  # Return:
  # - an array of record data if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    begin
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      if !params[:type].nil? and params[:type].upcase == 'A'
        @record=@domain.a_records.find(params[:id])
        @record.destroy
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @record=@domain.aaaa_records.find(params[:id])
        @record.destroy
      elsif !params[:type].nil? and params[:type].upcase == 'CNAME'
        @record=@domain.cname_records.find(params[:id])
        @record.destroy
      elsif !params[:type].nil? and params[:type].upcase == 'MX'
        @record=@domain.mx_records.find(:params[:id])
        @record.destroy
      elsif !params[:type].nil? and params[:type].upcase == 'NS'
        @record=@domain.ns_records.find(params[:id])
        @record.destroy
      elsif !params[:type].nil? and params[:type].upcase == 'TXT'
        @record=@domain.txt_records.find(params[:id])
        @record.destroy
      elsif !params[:type].nil? and params[:type].upcase == 'SOA'
        @record=@domain.soa_record.find(params[:id])
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
      @user = User.find(params[:user_id])
      @domain = @user.domains.find(params[:domain_id])
      if !params[:type].nil? and params[:type].upcase == 'A'
        @record=@domain.a_records.find(params[:id])
      elsif !params[:type].nil? and params[:type].upcase == 'AAAA'
        @record=@domain.aaaa_records.find(params[:id])
      elsif !params[:type].nil? and params[:type].upcase == 'CNAME'
        @record=@domain.cname_records.find(params[:id])
      elsif !params[:type].nil? and params[:type].upcase == 'MX'
        @record=@domain.mx_records.find(:params[:id])
      elsif !params[:type].nil? and params[:type].upcase == 'NS'
        @record=@domain.ns_records.find(params[:id])
      elsif !params[:type].nil? and params[:type].upcase == 'TXT'
        @record=@domain.txt_records.find(params[:id])
      elsif !params[:type].nil? and params[:type].upcase == 'SOA'
        @record=@domain.soa_record.find(params[:id])
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
