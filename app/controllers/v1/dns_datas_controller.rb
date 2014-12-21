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


class V1::DnsDatasController < ApplicationController
  before_filter :restrict_access, :is_admin

  def index
    domains = ''
    Domain.each do |d|
      domains += d.zone
      domains += ' '
    end
    render text: domains
  end

  def show
    domain = Domain.where(:zone => params[:zone]).first
    render text: domain.json_zone(params[:region]) unless domain.nil?
  end

  def check_list
    conf = []
    # Load cluster configurations
    Check.all.each do |check|
      conf.push(
          {
              :reference => "#{check.id.to_s}",
              :ip_address => check.ip,
              :check => check.check,
              :check_args => check.check_args,
              :enabled => check.enabled.to_s
          }
      )
    end

    render json: conf

  end

  def query_count

    hash = JSON.parse params['json']
    begin
      region = Region.find(hash['region'])
    rescue
      region = nil
    end

    hash['queryCount'].each do |stat|
      unless stat.nil?
        if stat.first.to_s[-1,1] == '.'
          d = stat.first.to_s[0...-1]
        else
          d = stat.first.to_s
        end
        logger.debug stat.first.to_s + ' - ' + d.to_s
        domain = Domain.where(zone: d).first
        unless domain.nil?
          graph_stat = domain.domain_statistics.new(count: stat.last.to_i,serverID: hash['serverID'])
          graph_stat.region = region
          graph_stat.save

          monthly_stat = domain.domain_monthly_stats.where(year: Date.today.year, month: Date.today.month).first
          if monthly_stat.nil?
            monthly_stat = domain.domain_monthly_stats.create(year: Date.today.year, month: Date.today.month, count: 0)
          end
          monthly_stat.update_attribute(:count, stat.last.to_i)
        end
      end
    end
  end

  def update_from_check
    check = Check.find(params[:id])
    status = check.choose_status(params[:status])
    status_change = false
    if status == 'OK'
      if check.hard_status
        # if is OK do nothing, only reset counter
        check.soft_count = 0
        check.soft_status = true
        check.hard_status = true
      else
        # if hard is in error
        check.soft_count += 1
        check.soft_status = true
        # check if I have to enable this host
        if check.soft_count >= check.soft_to_hard_to_enable
          check.hard_status = true
          check.soft_count = 0
          status_change = true
        end
      end
    else
      if check.hard_status
        # if hard is ok
        check.soft_count += 1
        check.soft_status = false
        # check if I have to enable this host
        if check.soft_count >= check.soft_to_hard_to_disable
          check.hard_status = false
          check.soft_count = 0
          status_change = true
        end
      else
        # if hard is error do nothing, only reset counter
        check.soft_count = 0
        check.soft_status = false
        check.hard_status = false
      end
    end

    check.save

    if status_change and not check.reports_only
      check.records.each do |record|
        record.operational = check.hard_status
        record.save
      end
      if Settings.notify_changes_to_check == 'true'
        Region.where(:has_check => true).each do |region|
          region.update_check_server(check.id.to_s)
        end
      end
    end
  end

end

