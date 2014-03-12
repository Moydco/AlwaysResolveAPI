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
    user = User.where(:user_reference => params[:id]).first
    if user == @user_id
      render json: @user_id.user_reference
    else
      render json: @user_id, :status => 500
    end
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
