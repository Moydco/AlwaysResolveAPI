class V1::UsersController < ApplicationController
  before_filter :restrict_access

  # ==== GET: /users/
  # Show all Users
  def index
  end

  # ==== PUT: /users/:id
  # Update User
  def update
  end

  # ==== DELETE: /users/:id
  # Delete User
  def destroy
  end
end
