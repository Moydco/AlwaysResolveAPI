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
