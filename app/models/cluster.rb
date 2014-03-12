# Attributes:
# - id: String, the local Cluster Record ID
# - name: String, the local Cluster name, must be unique
# - type: String, the type of cluster, must be one of ['HA', 'LB', 'GEO']
# - check: String, the type of check by nagios-plugins; empty to ping
# - check_args: String, the argouments of nagios plugin check
# - enabled: Boolean, if is enabled or disabled
# - condition_to_enable: String, the condition written in LUA to enable an host
# - condition_to_disable: String, the condition written in LUA to dis:able an host
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
  field :condition_to_enable, type: String
  field :condition_to_disable, type: String

  validates :name, :uniqueness => { scope: :domain_id }
  validates :type, inclusion: { in: %w(HA LB GEO) }, :allow_nil => false, :allow_blank => false

  belongs_to :domain
  has_many :geo_locations, :dependent => :destroy

  after_save :update_check_servers
  before_destroy :delete_from_check_servers

  def update_check_servers
    Region.where(:has_check => true).each do |region|
      logger.debug region.code
      self.geo_locations.each do |geo|
        geo.a_records.each do |host|
          UpdateCheckWorker.perform_async(host.id.to_s,region.id.to_s)
        end
      end
    end
  end

  def delete_from_check_servers
    true
  end
end
