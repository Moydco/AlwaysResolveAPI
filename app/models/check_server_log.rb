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
# - id: String, the local Check Record ID
# - signal: String, the signal coming from the check (OK, WARNING, ERROR, UNKNOWN)
# - log: String, the compete message coming from Nagios Plugin
# - server: String, the check server ID inside a region
# - change_to_hard: Boolean, if this event changed the hard state - Default: false
# Relations:
# - belongs_to check
# - belongs_to region

class CheckServerLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :signal, type: String
  field :log, type: String
  field :server, type: String
  field :change_to_hard, type: Boolean, default: false

  validates :signal, inclusion: { in: %w(OK WARNING ERROR UNKNOWN) }, :allow_nil => false, :allow_blank => false
  validates :server, :presence => true

  belongs_to :check
  belongs_to :region
end
