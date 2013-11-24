# Attributes:
# - signal: start or stop
# - log: optional exit log status
# Relations:
# - belongs_to :region

class ServerLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :signal, type: String
  field :log, type: String

  validates :signal, inclusion: { in: %w(START STOP) }, :allow_nil => false, :allow_blank => false
end
