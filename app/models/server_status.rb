# Attributes:
# - server: String, the DNS serer ID inside region
# Relations:
# - belongs_to :region
# - has_many :server_logs


class ServerStatus
  include Mongoid::Document
  include Mongoid::Timestamps

  field :server, type: String

  belongs_to :region

  has_many :server_logs
  validates :server,  :uniqueness => { scope: :region_id }
end
