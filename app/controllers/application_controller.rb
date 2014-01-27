class ApplicationController < ActionController::API
  before_filter :restrict_access
  after_filter :call_callback

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :null_session

  # Method called in every API where is mandatory (via before filter) to confirm user is the master of the requested resource
  def authorize_resource
    head :unauthorized  unless @user_id.user_reference.to_s == params[:user_id]
  end

  private

  # Method called in every API (via before filter) to check token validity. The token must be passet via GET patameter "st"
  def restrict_access
    logger.debug "Dentro a Restrict Access"
    unless controller_name == 'semi_static' # or controller_name == 'server_statuses' or controller_name == 'server_logs' or controller_name == 'regions'
      if params[:auth_method] == 'zotsell' or (params[:auth_method].nil? and Settings.auth_method == 'zotsell')
        user_id_from_api=check_token_on_zotsell params[:st]
      elsif params[:auth_method] == 'keystone' or (params[:auth_method].nil? and Settings.auth_method == 'keystone')
        key,value = request.query_string.split '=',2
        user_id_from_api = check_token_on_keystone value
      elsif params[:auth_method] == 'openebula' or (params[:auth_method].nil? and Settings.auth_method == 'openebula')
        user_id_from_api=check_token_on_zotsell params[:st]
      elsif params[:auth_method] == 'devise' or (params[:auth_method].nil? and Settings.auth_method == 'devise')
        user_id_from_api=check_token_on_devise params[:st]
      end

      unless user_id_from_api
        unless params[:api_key].nil?
          api_account = ApiAccount.find(params[:api_key])
          logger.debug api_account.api_secret
          user_id_from_api = api_account.user.user_reference if api_account.api_secret == params[:api_secret] and api_account.rights.include?(controller_name)
        end
      end

      logger.debug user_id_from_api
      logger.debug params[:user_id]

      unless user_id_from_api
        head :unauthorized
      else
        @user_id = User.find_or_create_by(:user_reference => user_id_from_api)
        @user_id.save
      end
    end
  end

  # Check the token validity in Zotsell compatible SSO
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

  # Check the token validity in OpenStack Keystone SSO
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
      if parsed['access']['token']['tenant']['id'].nil?
        return parsed['access']['user']['id']
      else
        return parsed['access']['user']['id'] + '-' + parsed['access']['token']['tenant']['id']
      end
    rescue
      false
    end
  end

  # Check the token validity in OpenNebula Auth system
  def check_token_on_opennebula(token)
    false
  end

  # Check the token validity in Devise Auth system
  def check_token_on_devise(token)
    url = URI.parse("#{Settings.auth_devise_url}#{Settings.token_devise_path}/?format=json")
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data({:user_token => token, :format => 'json'})
    sock = Net::HTTP.new(url.host, url.port)
    if Settings.auth_devise_url.starts_with? 'https'
      sock.use_ssl = true
      sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response=sock.start {|http| http.request(req) }
    begin
      logger.debug 'Dati da devise'
      logger.debug response.body
      parsed = JSON.parse(response.body)

      unless parsed['error'] == "Unauthorized"
        return parsed['_id']['$oid']
      else
        false
      end

    rescue

      false
    end
  end

  # Check admin credential
  #def check_admin
  #  unless params[:key] == Settings.admin_key and params[:password] == Settings.admin_password
  #    head :unauthorized
  #  end
  #end

  # Method called after every action that calls a callback URL to notify your App of the action done by the user
  def call_callback
    if Settings.send_callback == 'true'
      logger.debug "Call callback #{controller_name} - #{action_name} - #{params}"
      url = URI.parse("#{Settings.callback_url}#{Settings.callback_path}")
      if Settings.callback_method == 'POST'
        req = Net::HTTP::Post.new(url.path)
      else
        req = Net::HTTP::Get.new(url.path)
      end

      req.set_form_data({:params => params})
      sock = Net::HTTP.new(url.host, url.port)
      if Settings.callback_url.starts_with? 'https'
        sock.use_ssl = true
        sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response=sock.start {|http| http.request(req) }
    end
  end

  # Method to check if a record is enabled
  def enabled?(parameter)
    (parameter.upcase == 'TRUE') or (parameter == '1') or (parameter == 1) or (parameter == true)
  end

end
