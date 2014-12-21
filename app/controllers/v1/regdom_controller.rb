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


class V1::RegdomController < ApplicationController

  def index

    begin
      domain = params[:domain]
      tld = params[:tld]

      if !tld.nil? and !domain.nil?

        m = eval "Settings.domain_registers_#{tld}"
        m = Settings.domain_default_register if m.nil? or n.empty?

        logger.debug "lib/regdom/#{m}"
        logger.debug "include Regdom::#{m.humanize}"

        require "lib/regdom/#{m}"
        regdom = eval "Regdom::#{m.humanize}"

        if regdom.search_domain(domain,tld)
          render text: 'Not Available', status: 411
        else
          render text: 'Available', status: 200
        end
      else
        render text: 'Missinig required informations', status: 500
      end
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end
end
