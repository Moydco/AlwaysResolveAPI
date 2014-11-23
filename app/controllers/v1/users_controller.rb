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

  # ==== GET: /v1/users/:id/credit
  # Show User
  def credit
    if Settings.auth_method == 'oauth2'
      token = params[:st] || request.headers['X-Auth-Token']
      url = URI.parse("#{Settings.auth_oauth2_url}#{Settings.credit_oauth2_path}")
      logger.debug "url: #{url}, token: #{token}"
      req = Net::HTTP::Get.new(url.path, initheader = {'Authorization' => token})

      sock = Net::HTTP.new(url.host, url.port)
      if Settings.auth_oauth2_url.starts_with? 'https'
        sock.use_ssl = true
        sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response=sock.start {|http| http.request(req) }
      begin
        logger.debug 'Dati da oauth2'
        logger.debug response.body
      rescue
        render text: nil, :status => 500
      end
      render text: response.body
    else
      render text: nil, :status => 500
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
