class V1::UsersController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /v1/users/
  # Show all Users
  def index
    respond_to do |format|
      format.html {render text: @user_id}
      format.xml {render xml: @user_id}
      format.json {render json: @user_id}
    end
  end

  # ==== PUT: /v1/users/:id
  # Update User
  def update
  end

  # ==== DELETE: /v1/users/:id
  # Delete User
  def destroy
  end
end
