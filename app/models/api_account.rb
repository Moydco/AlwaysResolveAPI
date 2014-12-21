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
# - api_secret: String, the local API user Secret
# - rights, :type => Array, array of controllers enabled - Default: [] (empty array)
# Relations:
# - belongs_to User

class ApiAccount
  include Mongoid::Document
  before_create :set_secret
  validate :validate_array

  field :api_secret, type: String
  field :rights, :type => Array, :default => []

  belongs_to :user
  belongs_to :check

  # Return the key as string
  def api_key
    return self.id.to_s
  end

  # create a random secret
  def set_secret
    o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
    self.api_secret = (0...64).map{ o[rand(o.length)] }.join
  end

  private

  # check if there are wrong permissions
  def validate_array
    unless self.rights.empty?
      errors.add(:rights, 'Can\'t grant this right') if self.rights.include?('users')
    end
  end
end
