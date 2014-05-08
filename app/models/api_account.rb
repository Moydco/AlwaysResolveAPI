# Attributes:
# - api_secret: String, the local API user Secret
# - rights, :type => Array, array of controllers enabled
# Relations:
# - belongs_to User

class ApiAccount
  include Mongoid::Document
  before_create :set_secret
  validate :validate_array

  field :api_secret, type: String
  field :rights, :type => Array, :default => []

  belongs_to :user

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
