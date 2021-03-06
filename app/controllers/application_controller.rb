# --------------------------------------------------------------------------- #
# Copyright 2013-2015, AlwaysResolve Project (alwaysresolve.org), MOYD.CO LTD #
#                                                                             #
# Licensed under the Apache License, Version 2.0 (the "License"); you may     #
# not use this file except in compliance with the License. You may obtain     #
# a copy of the License at                                                    #
#                                                                             #
# http://www.apache.org/licenses/LICENSE-2.0                                  #
#                                                                             #
# Unless required by applicable law or agreed to in writing, software         #
# distributed under the License is distributed on an "AS IS" BASIS,           #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    #
# See the License for the specific language governing permissions and         #
# limitations under the License.                                              #
# --------------------------------------------------------------------------- #


class ApplicationController < ActionController::API
  before_filter :cors_preflight_check, :restrict_access
  after_filter :call_callback, :cors_set_access_control_headers

  # For all responses in this controller, return the CORS access control headers.
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS, PUT, DELETE'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.
  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS, PUT, DELETE'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end

  # Method called in every API where is mandatory (via before filter) to confirm user is the master of the requested resource
  def authorize_resource
    head :unauthorized  unless !@user_id.nil? and @user_id.user_reference.to_s == params[:user_id]
  end

  private

  def is_admin
    return @user_id.is_admin?
  end

  # Method called in every API (via before filter) to check token validity. The token must be passet via GET patameter "st"
  def restrict_access
    logger.debug "Inside Restrict Access"
    unless controller_name == 'semi_static'

      user_id_from_api=nil

      unless controller_name == 'dns_server_statuses' or controller_name == 'dns_server_logs' or controller_name == 'dns_datas'
        if params[:auth_method] == 'zotsell' or (params[:auth_method].nil? and Settings.auth_method == 'zotsell')
          user_id_from_api=check_token_on_zotsell params[:st]
        elsif params[:auth_method] == 'keystone' or (params[:auth_method].nil? and Settings.auth_method == 'keystone')
          # key,value = request.query_string.split '=',2
          user_id_from_api = check_token_on_keystone params[:st] #value
        elsif params[:auth_method] == 'openebula' or (params[:auth_method].nil? and Settings.auth_method == 'openebula')
          user_id_from_api=check_token_on_zotsell params[:st]
        elsif params[:auth_method] == 'oauth2' or (params[:auth_method].nil? and Settings.auth_method == 'oauth2')
          logger.debug "Scelgo OAuth2 per l'autenticazione"
          user_id_from_api=check_token_on_oauth2(params[:st],request.headers['X-Auth-Token'])
          logger.debug "user_id_from_api dopo oauth2: #{user_id_from_api}"
        end
      end

      if user_id_from_api.nil? or !user_id_from_api
        logger.debug 'user not found, trying with api'
        unless params[:api_key].nil?
          api_account = ApiAccount.find(params[:api_key])
          logger.debug "Api Secret: " + api_account.api_secret.to_s
          logger.debug "Api Secret: " + params[:api_secret]
          logger.debug "#{api_account.api_secret == params[:api_secret]}"
          logger.debug "Controller name: " + controller_name.to_s
          logger.debug "Controller name included: #{api_account.rights.include?(controller_name)}"

          user_id_from_api = api_account.user.user_reference if api_account.api_secret == params[:api_secret] and
              api_account.rights.include?(controller_name)

          logger.debug "User reference: #{api_account.user.user_reference}"
          logger.debug "User ID prima dell'uscita #{user_id_from_api}"
        end
      end

      logger.debug "User from api key/secret: #{user_id_from_api}"

      if user_id_from_api.nil? || !user_id_from_api
        head :unauthorized
      else
        logger.debug("User ID from api: #{user_id_from_api}")
        begin
          @user_id = User.find(user_id_from_api)
        rescue
          @user_id = User.create(:user_reference => user_id_from_api)
        end
        # @user_id.save
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

  # Check the token validity in OAuth2 system
  def check_token_on_oauth2(st,hd)
    token = st || hd
    begin
      user_from_token = JSON.parse(JWT.decode(token, Settings.oauth2_id).first)
      logger.debug user_from_token
    rescue
      logger.debug 'Token not correct: '
      logger.debug token unless token.nil?
      return false
    end
    url = URI.parse("#{Settings.auth_oauth2_url}#{Settings.token_oauth2_path}/?format=json")
    logger.debug "url: #{url}, token: #{token}"
    req = Net::HTTP::Post.new(url.path, initheader = {'Authorization' => token})

    sock = Net::HTTP.new(url.host, url.port)
    if Settings.auth_oauth2_url.starts_with? 'https'
      sock.use_ssl = true
      sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response=sock.start {|http| http.request(req) }
    begin
      logger.debug 'Dati da oauth2'
      logger.debug response.body

      if response.body == 'Error'
        false
      elsif user_from_token.nil? or user_from_token["_id"].nil? or user_from_token["_id"]["$oid"].nil? or user_from_token.blank? or user_from_token["_id"].blank? or user_from_token["_id"]["$oid"].blank?
        false
      else
        user_from_token["_id"]["$oid"] + '-oauth2'
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
