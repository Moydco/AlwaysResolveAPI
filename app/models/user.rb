# Attributes:
# - id: String, the local user ID
# - user_reference: String, the reference ID of user in SSO server, must be unique
# - admin: Boolean, if is an admin user which has access to dns_datas, regions,
# Relations:
# - has_many Domain
# - has_many ApiAccount
# We use slug to find User by user_reference (the value in your server) instead of local Id

class User
  include Mongoid::Document
  include Mongoid::Slug

  field :user_reference, type: String
  field :admin, type: Boolean, default: false
  slug :user_reference

  validates :user_reference,  :uniqueness => true

  has_many :domains, :dependent => :destroy
  has_many :api_accounts, :dependent => :destroy

  has_many :checks

  def is_admin?
    return self.admin
  end

end
