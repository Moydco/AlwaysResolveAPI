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


# Attributes:
# - country_code: String, two-letters country code (ex. IT, US)
# - code: String, provider reference for country code (ex. IT001, US004)
# - dns_ip_address: String, the ip address of local RabbitMQ server
# - check_ip_address: String, the ip address of local Check server
# - has_dns: Boolean, if in this region there are DNS server - Default: true
# - has_check: Boolean, if in this region there are Check server - Default: true
# Relations
# - has_many :dns_server_statuses
# - has_many :dns_server_logs
# - has_many :cluster_server_logs
# - has_many :neighbor_regions
# - has_many :geo_location

class Region
  include Mongoid::Document
  include HTTParty

  field :country_code, type: String
  field :code, type: String
  field :dns_ip_address, type: String
  field :check_ip_address, type: String
  field :has_dns, type: Boolean, default: true
  field :has_check, type: Boolean, default: true

  field :domains_to_update, type: Array, default: []

  has_many :dns_server_statuses
  has_many :dns_server_logs
  has_many :check_server_logs

  has_many :neighbor_regions, :inverse_of => :owner
  has_many :records
  has_many :domain_statistics

  validates :code, :allow_nil => false, :allow_blank => false, :uniqueness => true
  validates :dns_ip_address, :presence => true, :format => { :with => Resolv::IPv4::Regex }, :if => :should_validate_dns_ip_address?
  validates :check_ip_address, :presence => true, :format => { :with => Resolv::IPv4::Regex }, :if => :should_validate_check_ip_address?

  def should_validate_dns_ip_address?
    self.has_dns
  end

  def should_validate_check_ip_address?
    self.has_check
  end

  def update_check_server(check_id)
    check = Check.find(check_id)
    if check.hard_status
      status = 'OK'
    else
      status = 'CRITICAL'
    end
    data = self.class.put("http://#{self.check_ip_address}:#{Settings.check_server_port}/#{Settings.update_path}/#{check_id}", :body => {
        :reference => check_id,
        :ip_address => check.ip,
        :check => check.check,
        :check_args => check.check_args,
        :enabled => check.enabled,
        :last_status => status,
        :format => 'json'
    })
  end

  def delete_from_check_server(check_id)
    data = self.class.delete("http://#{self.check_ip_address}:#{Settings.check_server_port}/#{Settings.delete_path}/#{check_id}", :query => {
        :reference => check_id,
        :format => 'json'
    })
  end

  def update_dns_from_queue
    self.domains_to_update.each do |d|
      Domain.find(d).send_to_local_rabbit(:update,self)
      self.domains_to_update.pull(d)
    end
  end
end

