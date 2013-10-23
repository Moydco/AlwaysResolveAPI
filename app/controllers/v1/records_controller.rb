class V1::RecordsController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /users/:user_id/domains/:domain_id/records/
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
      if params[:type] == 'A'
        @records=@domain.a_records
      elsif params[:type] == 'AAAA'
        @records=@domain.aaaa_records
      elsif params[:type] == 'CNAME'
        @records=@domain.cname_records
      elsif params[:type] == 'MX'
        @records=@domain.mx_records
      elsif params[:type] == 'NS'
        @records=@domain.ns_records
      elsif params[:type] == 'SOA'
        @records=@domain.soa_record
      elsif params[:type] == 'TXT'
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
        format.html {render text: @records}
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

  # ==== POST: /users/:user_id/domains/:domain_id/records/
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
      if params[:type] == 'A'
        @record=@domain.a_records.create!(:name => params[:name], :ip => params[:ip], :enabled => params[:enabled])
      elsif params[:type] == 'AAAA'
        @record=@domain.aaaa_records.create!(:name => params[:name], :ip => params[:ip], :enabled => params[:enabled])
      elsif params[:type] == 'CNAME'
        @record=@domain.cname_records.create!(:name => params[:name], :value => params[:value], :enabled => params[:enabled])
      elsif params[:type] == 'MX'
        @record=@domain.mx_records.create!(:name => params[:name], :value => params[:value], :priority => params[:priority], :enabled => params[:enabled])
      elsif params[:type] == 'NS'
        @record=@domain.ns_records.create!(:name => params[:name], :value => params[:value], :enabled => params[:enabled])
      elsif params[:type] == 'TXT'
        @record=@domain.txt_records.create!(:name => params[:name], :value => params[:value], :enabled => params[:enabled])
      else
        @record=nil
      end
      unless @record.nil?
        respond_to do |format|
          format.html {render text: @record}
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

  # ==== PUT: /users/:user_id/domains/:domain_id/records/:id
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
      if params[:type] == 'A'
        @record=@domain.a_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :ip => params[:ip], :enabled => params[:enabled])
      elsif params[:type] == 'AAAA'
        @record=@domain.aaaa_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :ip => params[:ip], :enabled => params[:enabled])
      elsif params[:type] == 'CNAME'
        @record=@domain.cname_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :value => params[:value], :enabled => params[:enabled])
      elsif params[:type] == 'MX'
        @record=@domain.mx_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :value => params[:value], :priority => params[:priority], :enabled => params[:enabled])
      elsif params[:type] == 'NS'
        @record=@domain.ns_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :value => params[:value], :enabled => params[:enabled])
      elsif params[:type] == 'TXT'
        @record=@domain.txt_records.find(params[:id])
        @record.update_attributes!(:name => params[:name], :value => params[:value], :enabled => params[:enabled])
      elsif params[:type] == 'SOA'
        @record=@domain.soa_record.find(params[:id])
        @record.update_attributes!(:mname => params[:mname], :rname => params[:rname], :at => params[:at], :refresh => params[:resfresh], :retry => params[:retry], :expire => params[:expire], :minimum => params[:minimum])
      else
        @record=nil
      end
      unless @record.nil?
        respond_to do |format|
          format.html {render text: @record}
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

  # ==== DELETE: /users/:user_id/domains/:domain_id/records/:id
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
      if params[:type] == 'A'
        @record=@domain.a_records.find(params[:id])
        @record.destroy
      elsif params[:type] == 'AAAA'
        @record=@domain.aaaa_records.find(params[:id])
        @record.destroy
      elsif params[:type] == 'CNAME'
        @record=@domain.cname_records.find(params[:id])
        @record.destroy
      elsif params[:type] == 'MX'
        @record=@domain.mx_records.find(:params[:id])
        @record.destroy
      elsif params[:type] == 'NS'
        @record=@domain.ns_records.find(params[:id])
        @record.destroy
      elsif params[:type] == 'TXT'
        @record=@domain.txt_records.find(params[:id])
        @record.destroy
      elsif params[:type] == 'SOA'
        @record=@domain.soa_record.find(params[:id])
        @record.destroy
      else
        @record=nil
      end
      unless @record.nil?
        respond_to do |format|
          format.html {render text: @record}
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

  # ==== GET: /users/:user_id/domains/:domain_id/records/:id
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
      if params[:type] == 'A'
        @record=@domain.a_records.find(params[:id])
      elsif params[:type] == 'AAAA'
        @record=@domain.aaaa_records.find(params[:id])
      elsif params[:type] == 'CNAME'
        @record=@domain.cname_records.find(params[:id])
      elsif params[:type] == 'MX'
        @record=@domain.mx_records.find(:params[:id])
      elsif params[:type] == 'NS'
        @record=@domain.ns_records.find(params[:id])
      elsif params[:type] == 'TXT'
        @record=@domain.txt_records.find(params[:id])
      elsif params[:type] == 'SOA'
        @record=@domain.soa_record.find(params[:id])
      else
        @record=nil
      end
      unless @record.nil?
        respond_to do |format|
          format.html {render text: @record}
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
