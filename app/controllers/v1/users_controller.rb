class V1::UsersController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /v1/users/
  # Show User ID of current user
  def index
    respond_to do |format|
      format.html {render text: @user_id.user_reference}
      format.xml {render xml: @user_id.user_reference}
      format.json {render json: @user_id.user_reference}
    end
  end

  # ==== GET: /v1/users/:id
  # Update User
  def show
    respond_to do |format|
      format.html {render text: @user_id.domains.count}
      format.xml {render xml: @user_id.domains}
      format.json {render json: @user_id.domains}
    end
  end

end
