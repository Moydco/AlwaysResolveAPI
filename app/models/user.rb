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
# - id: String, the local user ID
# - user_reference: String, the reference ID of user in SSO server, must be unique
# - admin: Boolean, if is an admin user which has access to dns_datas, regions - Default: false
# Relations:
# - has_many Domain
# - has_many ApiAccount
# We use slug to find User by user_reference (the value in your server) instead of local Id

class User
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  field :user_reference, type: String
  field :admin, type: Boolean, default: false
  field :email, type: String
  field :sms, type: String
  field :notify_by_email, type: Boolean, default: false
  field :notify_by_sms, type: Boolean, default: false

  slug :user_reference

  validates :user_reference,  :uniqueness => true

  has_many :domains, :dependent => :destroy
  has_many :api_accounts, :dependent => :destroy

  has_many :checks

  has_many :contacts
  has_many :domain_registrations

  def is_admin?
    return self.admin
  end

end
