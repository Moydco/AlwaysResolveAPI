class V1::UsersController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /v1/users/
  # Show User ID of current user
  def index
    render json: @user_id.user_reference
  end

  # ==== GET: /v1/users/:id
  # Update User
  def show
    render json: @user_id.domains
  end

  # ==== DELETE: /v1/users/:id
  # Update User
  def destroy
    if @user_id.destroy
      render json: @user_id.user_reference
    else
      render json: @user_id.user_reference, :status => 500
    end
  end
end
