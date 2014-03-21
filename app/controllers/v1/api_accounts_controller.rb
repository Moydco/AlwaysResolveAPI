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
      user = User.find(params[:user_id])
      api_accounts = user.api_accounts
      render json: api_accounts
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
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
      api_account = User.find(params[:user_id]).api_accounts.find(params[:id])
      render json: api_account
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== POST: /v1/users/:user_id/api_accounts
  # Create an api accounts owned by User
  #
  # Params:
  # - user_id: the id of the user
  # - api_account -> rights: Array, the name of controllers enabled for this api account
  # Return:
  # - an array of user's api account details if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      api_account = User.find(params[:user_id]).api_accounts.create!(api_accounts_params)
      render json: api_account
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== PUT: /v1/users/:user_id/api_accounts/:id
  # Update an api accounts
  #
  # Params:
  # - user_id: the id of the user
  # - api_account -> rights: Array, the name of controllers enabled for this api account
  # Return:
  # - an array of user's api account details if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      api_account = User.find(params[:user_id]).api_accounts.find(params[:id])
      api_account.update!(api_accounts_params)
      #api_account.update_attributes(rights: params["api_account"]["rights"])
      render json: api_account
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== DELETE: /v1/users/:user_id/api_accounts/:id
  # Delete an api accounts
  #
  # Params:
  # - user_id: the id of the user
  # Return:
  # - an array of user's api account details if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    begin
      api_account = User.find(params[:user_id]).api_accounts.find(params[:id]).destroy
      render json: api_account
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  private

  def api_accounts_params
    params.require(:api_account).permit(
        :rights => []
    )
  end
end
