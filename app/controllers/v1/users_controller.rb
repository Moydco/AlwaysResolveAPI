class V1::UsersController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /v1/users/
  # Show User ID of current user
  def index
    render json: @user_id.user_reference
  end

  # ==== GET: /v1/users/:id
  # Show User
  def show
    user = User.where(:user_reference => params[:id]).first
    if user == @user_id
      render json: @user_id
    else
      render json: nil, :status => 500
    end
  end

  # ==== PUT: /v1/users/:id
  # Update User
  def update
    user = User.where(:user_reference => params[:id]).first
    if user == @user_id
      if user.update_attributes(user_params)
        render json: @user_id
      else
        render json: @user_id, status: 500
      end
    else
      render json: nil, :status => 500
    end
  end

  # ==== DELETE: /v1/users/:id
  # Delete User
  def destroy
    if @user_id.destroy
      render json: @user_id.user_reference
    else
      render json: @user_id.user_reference, :status => 500
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :sms, :notify_by_email, :notify_by_sms)
  end
end
