# Attributes:
# - code: String, two-letters country code (ex. IT, US)
# - ip_address: String, the ip address of local RabbitMQ server
# Relations
# - has_many :server_statuses
# - has_many :server_logs

class Region
  include Mongoid::Document
  field :code, type: String
  field :ip_address, type: String

  has_many :server_statuses
  has_many :server_logs

  validates :code, :allow_nil => false, :allow_blank => false, :uniqueness => true
  validates :ip_address, :presence => true, :format => { :with => Resolv::IPv4::Regex }
end

