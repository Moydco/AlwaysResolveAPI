class V1::ChecksController < ApplicationController
  before_filter :restrict_access

  before_filter :authorize_resource

  # ==== GET: /v1/users/:user_id/checks
  # Return the check for a domain
  #
  # Params:
  # - user_id: the id of the user
  # Return:
  # - a description of the check if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    begin
      check = User.find(params[:user_id]).checks

      render json: check
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== POST: /v1/users/:user_id/checks
  # Create a check that will be linked with cluster or record
  #
  # Params:
  # - user_id: the id of the user
  #
  # - check => ip: String, the IP address of the server checked
  # - check => check: String, the type of check by nagios-plugins; empty to ping
  # - check => check_args: String, the arguments of nagios plugin check
  # - check => soft_to_hard_to_enable: Integer, the number of consecutive checks OK to consider an host UP
  # - check => soft_to_hard_to_disable: Integer, the number of consecutive checks Error to consider an host Down
  # - check => enabled: Boolean, if is enabled or disabled
  # Return:
  # - a description of the check if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    begin
      check = User.find(params[:user_id]).checks.create!(check_params)

      render json: check
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== PUT: /v1/users/:user_id/checks/:id
  # Create a check that will be linked with cluster or record
  #
  # Params:
  # - user_id: the id of the user
  #
  # - check => ip: String, the ip address of the server checked
  # - check => check: String, the type of check by nagios-plugins; empty to ping
  # - check => check_args: String, the arguments of nagios plugin check
  # - check => soft_to_hard_to_enable: Integer, the number of consecutive checks OK to consider an host UP
  # - check => soft_to_hard_to_disable: Integer, the number of consecutive checks Error to consider an host Down
  # - check => enabled: Boolean, if is enabled or disabled
  # Return:
  # - a description of the check if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    begin
      check = User.find(params[:user_id]).checks.find(params[:id])
      check.update!(check_params)

      render json: check
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== DELETE: /v1/users/:user_id/checks/:id
  # Delete a check
  #
  # Params:
  # - user_id: the id of the user
  # - check_id: the id of the check
  # Return:
  # - a description of the deleted check if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    begin
      check = User.find(params[:user_id]).checks.find(params[:id])
      check.destroy

      render json: check
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== GET: /v1/users/:user_id/checks/:id
  # Show the logs for a check
  #
  # Params:
  # - user_id: the id of the user
  # - id: the id of the check
  #
  # - page => start_day: days ago from today
  # - page => end_day: days ago from today
  # - page => page: the page number
  # - page => per_page: number of results per page
  # Return:
  # - a description of the deleted check if success with 200 code
  # - an error string with the error message if error with code 404
  def show
    begin
      check = User.find(params[:user_id]).checks.find(params[:id])

      logs = check.check_server_logs.where(:created_at.gte => (Date.today - params[:end_day]), :created_at.lte => (Date.today - params[:start_day])).page(params[:page]).per(params[:per_page]).all.to_a

      render json: logs
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  # ==== GET: /v1/users/:user_id/checks/:id/show_records
  # Show the records for a check
  #
  # Params:
  # - user_id: the id of the user
  # - id: the id of the check
  #
  # - page => start_day: days ago from today
  # - page => end_day: days ago from today
  # - page => page: the page number
  # - page => per_page: number of results per page
  # Return:
  # - a description of the deleted check if success with 200 code
  # - an error string with the error message if error with code 404
  def show_records
    begin
      check = User.find(params[:user_id]).checks.find(params[:id])

      render json: check.records
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  def check_params
    params.require(:check).permit(
        :name,
        :ip,
        :check,
        :check_args,
        :soft_to_hard_to_enable,
        :soft_to_hard_to_disable,
        :enabled,
        :reports_only
    )

  end

  def paginate_parmas
    params.require(:check).permit(
        :start_day,
        :end_day,
        :page,
        :per_page
    )
  end
end
