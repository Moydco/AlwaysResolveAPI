# Attributes:
# - id: String, the local user ID
# - user_reference: String, the reference ID of user in SSO server, must be unique
# - token: String, the authentication token by SSO
# Relations:
# - has_many Domain

class User
  include Mongoid::Document
  field :user_reference, type: String
  field :token, type: String

  validates :user_reference,  :uniqueness => true

  has_many :domains
end
