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
