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


class V1::SessionsController < ApplicationController
  before_filter :restrict_access

  def destroy
    if Settings.auth_method == 'oauth2'
      token = params[:st] || request.headers['X-Auth-Token']
      url = URI.parse("#{Settings.signout_oauth2_path}" + params[:id])
      logger.debug "url: #{url}, token: #{token}"
      req = Net::HTTP::Delete.new(url.path, initheader = {'Authorization' => token})

      sock = Net::HTTP.new(url.host, url.port)
      if Settings.auth_oauth2_url.starts_with? 'https'
        sock.use_ssl = true
        sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response=sock.start {|http| http.request(req) }
      begin
        logger.debug 'Dati da oauth2'
        logger.debug response.body
        render text: response.body
      rescue
        render text: nil, :status => 500
      end
    else
      render text: nil, :status => 500
    end
  end
end
