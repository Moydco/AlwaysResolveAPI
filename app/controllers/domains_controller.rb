class DomainsController < ApplicationController

  # ==== GET: /users/:user_id/domains
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
      respond_to do |format|
        format.html {render text: @domains.pluck(:id, :zone)}
        format.xml {render xml: @domains}
        format.json {render json: @domains}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== GET: /users/:user_id/domains/:id
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
      respond_to do |format|
        format.html {render text: (@domain.id.to_s + ': ' + @domain.zone)}
        format.xml {render xml: @domain}
        format.json {render json: @domain}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== POST: /users/:user_id/domains
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
      respond_to do |format|
        format.html {render text: (@domain.id.to_s + ': ' + @domain.zone)}
        format.xml {render xml: @domain}
        format.json {render json: @domain}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== PUT: /users/:user_id/domains/:id
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
      respond_to do |format|
        format.html {render text: (@domain.id.to_s + ': ' + @domain.zone)}
        format.xml {render xml: @domain}
        format.json {render json: @domain}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== DELETE: /users/:user_id/domains/:id
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
        respond_to do |format|
          format.html {render text: (@domain.id.to_s + ': ' + @domain.zone)}
          format.xml {render xml: @domain}
          format.json {render json: @domain}
        end
      else
        respond_to do |format|
          format.html {render text: "#{e.message}" }
          format.xml {render xml: {error: "Error deleting domain"}, status: 404 }
          format.json {render json: {error: "Error deleting domain"}, status: 404 }
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
