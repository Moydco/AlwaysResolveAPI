class ApplicationController < ActionController::Base
  before_filter :restrict_access

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  def authorize_resource
    head :unauthorized  unless @user_id.id.to_s == params[:user_id]
  end

  private

  def restrict_access
    if Settings.auth_method == 'zotsell'
      user_id_from_api=check_token_on_zotsell params[:st]
    elsif Settings.auth_method == 'keystone'
      key,value = request.query_string.split '=',2
      user_id_from_api=check_token_on_keystone value
    end

    unless user_id_from_api
      head :unauthorized
    else
      @user_id = User.find_or_create_by(:user_reference => user_id_from_api)
      @user_id.save
    end
  end

  def check_token_on_zotsell(token)
    url = URI.parse("#{Settings.auth_zotsell_url}#{Settings.token_zotsell_path}")
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data({:token => token})
    sock = Net::HTTP.new(url.host, url.port)
    if Settings.auth_zotsell_url.starts_with? 'https'
      sock.use_ssl = true
      sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response=sock.start {|http| http.request(req) }
    begin
      parsed = JSON.parse(response.body)

      if parsed['status'].to_i == 1
        return parsed['info']['uid']
      else
        false
      end

    rescue
      false
    end
  end

  def check_token_on_keystone(token)
    url = URI.parse("#{Settings.auth_keystone_url}#{Settings.token_keystone_path}#{token}")
    logger.debug url.host
    logger.debug url.port
    logger.debug url.path
    req = Net::HTTP::Get.new(url.path, initheader = {'X-Auth-Token' => Settings.keystone_admin_token})
    sock = Net::HTTP.new(url.host, url.port)
    if Settings.auth_keystone_url.starts_with? 'https'
      sock.use_ssl = true
      sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response=sock.start {|http| http.request(req) }
    begin
      parsed = JSON.parse(response.body)
      return parsed['access']['user']['id']
    rescue
      false
    end
  end
end
