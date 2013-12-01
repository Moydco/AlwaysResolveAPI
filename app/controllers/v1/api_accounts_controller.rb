class V1::ApiAccountsController < ApplicationController
  before_filter :restrict_access

  before_filter :authorize_resource

  # ==== GET: /v1/users/:user_id/api_accounts
  # Return all api accounts owned by User
  #
  # Params:
  # - user_id: the id of the user
  # Return:
  # - an array of user's api account if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    begin
      @user = User.find(params[:user_id])
      @api_accounts = @user.api_accounts
      respond_to do |format|
        format.html {render text: @api_accounts.pluck(:id, :api_secret).to_json}
        format.xml {render xml: @api_accounts}
        format.json {render json: @api_accounts}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== GET: /v1/users/:user_id/api_accounts/:id
  # Return the deatils of an api accounts owned by User
  #
  # Params:
  # - user_id: the id of the user
  # - id: the id
  # Return:
  # - an array of user's api account if success with 200 code
  # - an error string with the error message if error with code 404
  def show
    begin
      @api_account = User.find(params[:user_id]).api_accounts.find(params[:id])
      respond_to do |format|
        format.html {render text: @api_account.to_json}
        format.xml {render xml: @api_account}
        format.json {render json: @api_account}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== POST: /v1/users/:user_id/api_accounts
  # Create an api accounts owned by User
  #
  # Params:
  # - user_id: the id of the user
  # - rights: the name of controllers enabled for this api account
  # Return:
  # - an array of user's api account details if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      @api_account = User.find(params[:user_id]).api_accounts.create!(:rights => params[:rights])
      respond_to do |format|
        format.html {render text: @api_account.to_json}
        format.xml {render xml: @api_account}
        format.json {render json: @api_account}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== PUT: /v1/users/:user_id/api_accounts/:id
  # Update an api accounts
  #
  # Params:
  # - user_id: the id of the user
  # - rights: the name of controllers enabled for this api account
  # Return:
  # - an array of user's api account details if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      @api_account = User.find(params[:user_id]).api_accounts.find(params[:id]).update_attributes(:rights => params[:rights])
      respond_to do |format|
        format.html {render text: @api_account.to_json}
        format.xml {render xml: @api_account}
        format.json {render json: @api_account}
      end
    rescue => e
      respond_to do |format|
        format.html {render text: "#{e.message}" }
        format.xml {render xml: {error: "#{e.message}"}, status: 404 }
        format.json {render json: {error: "#{e.message}"}, status: 404 }
      end
    end
  end

  # ==== DELETE: /v1/users/:user_id/api_accounts/:id
  # Delete an api accounts
  #
  # Params:
  # - user_id: the id of the user
  # - rights: the name of controllers enabled for this api account
  # Return:
  # - an array of user's api account details if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    begin
      @api_account = User.find(params[:user_id]).api_accounts.find(params[:id]).destroy
      respond_to do |format|
        format.html {render text: @api_account.to_json}
        format.xml {render xml: @api_account}
        format.json {render json: @api_account}
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
