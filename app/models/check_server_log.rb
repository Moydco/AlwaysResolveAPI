# Attributes:
# - id: String, the local Check Record ID
# - signal: String, the signal coming from the check (OK, WARNING, ERROR, UNKNOWN)
# - log: String, the compete message coming from Nagios Plugin
# - server: String, the check server ID inside a region
# - change_to_hard: Boolean, if this event changed the hard state
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
