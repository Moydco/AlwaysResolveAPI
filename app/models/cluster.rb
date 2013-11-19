# Attributes:
# - id: String, the local Cluster Record ID
# - name: String, the local Cluster name, must be unique
# - type: String, the type of cluster, must be one of ['HA', 'LB', 'GEO']
# - check: String, the type of check by nagios-plugins; empty to ping
# - check_args: String, the argouments of nagios plugin check
# - enabled: Boolean, if is enabled or disabled (used by check server procedure)
# Relations:
# - belongs_to Domain
# - has_many GeoDns

class Cluster
  include Mongoid::Document

  field :name, type: String
  field :type, type: String
  field :check, type: String
  field :check_args, type: String
  field :enabled, type: Boolean, :default => true

  validates :name, :uniqueness => true
  validates :type, inclusion: { in: %w(HA LB GEO) }, :allow_nil => false, :allow_blank => false
  belongs_to :domain
  has_many :geo_locations, :dependent => :destroy

end
