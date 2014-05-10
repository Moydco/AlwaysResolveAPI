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

  def is_admin
    return @user_id.is_admin?
  end

  # Method called in every API (via before filter) to check token validity. The token must be passet via GET patameter "st"
  def restrict_access
    logger.debug "Inside Restrict Access"
    unless controller_name == 'semi_static'


      if controller_name == 'dns_server_statuses' or controller_name == 'dns_server_logs' or controller_name == 'dns_datas'
        user_id_from_api=nil
      else
        if params[:auth_method] == 'zotsell' or (params[:auth_method].nil? and Settings.auth_method == 'zotsell')
          user_id_from_api=check_token_on_zotsell params[:st]
        elsif params[:auth_method] == 'keystone' or (params[:auth_method].nil? and Settings.auth_method == 'keystone')
          # key,value = request.query_string.split '=',2
          user_id_from_api = check_token_on_keystone params[:st] #value
        elsif params[:auth_method] == 'openebula' or (params[:auth_method].nil? and Settings.auth_method == 'openebula')
          user_id_from_api=check_token_on_zotsell params[:st]
        elsif params[:auth_method] == 'devise' or (params[:auth_method].nil? and Settings.auth_method == 'devise')
          logger.debug "Scelgo devise per l'autenticazione"
          user_id_from_api=check_token_on_devise(params[:st],request.headers['X-API-Token'])
          logger.debug "user_id_from_api: #{user_id_from_api}"
        end
      end

      unless user_id_from_api
        logger.debug 'user not found'
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
        return parsed['info']['uid']  + '-zotsell'
      else
        false
      end

    rescue
      false
    end
  end

  # Check the token validity in OpenStack Keystone SSO
  def check_token_on_keystone(token)
    url = URI.parse("#{Settings.auth_keystone_url}#{Settings.token_keystone_path}")

    payload = {
        "auth" => {
            "passwordCredentials" => {
                "username" => Settings.keystone_admin_user,
                "password" => Settings.keystone_admin_password
            },
            "tenantId"=> Settings.keystone_admin_tenant
        }
    }
    # Retrieve the admin token
    admin_token_req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
    admin_token_req.body = payload.to_json
    sock = Net::HTTP.new(url.host, url.port)
    if Settings.auth_keystone_url.starts_with? 'https'
      sock.use_ssl = true
      sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    begin
      response=sock.start {|http| http.request(admin_token_req) }
      parsed = JSON.parse(response.body)
      logger.debug "Admin token: #{parsed['access']['token']['id']}"
      keystone_admin_token = parsed['access']['token']['id']

    rescue
      keystone_admin_token = false
    end
    if keystone_admin_token
      url = URI.parse("#{Settings.auth_keystone_url}#{Settings.token_keystone_path}#{token}")
      user_id_req = Net::HTTP::Get.new(url.path, initheader = {'X-Auth-Token' => keystone_admin_token})
      sock = Net::HTTP.new(url.host, url.port)
      if Settings.auth_keystone_url.starts_with? 'https'
        sock.use_ssl = true
        sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      begin
        response=sock.start {|http| http.request(user_id_req) }
        parsed = JSON.parse(response.body)
        if parsed['access']['token']['tenant']['id'].nil?
          return parsed['access']['user']['id'] + '-keystone'
        else
          return parsed['access']['user']['id'] + '-' + parsed['access']['token']['tenant']['id'] + '-keystone'
        end
      rescue
        false
      end
    else
      false
    end
  end

  # Check the token validity in OpenNebula Auth system
  def check_token_on_opennebula(token)
    false
  end

  # Check the token validity in Devise Auth system
  def check_token_on_devise(st,hd)
    token = st || hd
    url = URI.parse("#{Settings.auth_devise_url}#{Settings.token_devise_path}/?format=json")
    logger.debug "url: #{url}, token: #{token}"
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
        return parsed['_id']['$oid'] + '-devise'
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
