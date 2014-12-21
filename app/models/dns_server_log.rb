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
# - server: server id in datacenter
# - signal: start or stop
# - log: optional exit log status
# Relations:
# - belongs_to :region

class DnsServerLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :signal, type: String
  field :log, type: String
  field :server, type: String

  validates :signal, inclusion: { in: %w(START STOP) }, :allow_nil => false, :allow_blank => false
  validates :server, :presence => true

  belongs_to :region

end
