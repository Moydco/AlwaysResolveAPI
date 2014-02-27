# Attributes:
# - id: String, the local A Record ID
# - name: String, the local A name, must be unique
# - priority: Integer, default 1, the priority in resolution when used in a HA cluster object (small number = high priority)
# - weight: Integer, default 1, the weight in resolution when used in a LB cluster object (small number = small weight)
# - ip: String, the IP Address which resolves, must be a valid IPv4 address
# - enabled: Boolean, if is enabled or disabled
# - operational: Boolean, if is enabled or disabled (used by check server procedure)
# - on_check: Array, check servers that are checking this host (used by check server procedure)

# Relations:
# - belongs_to Domain
# - belongs_to GeoDns
# - has_many ClusterServerLog

class ARecord
  include Mongoid::Document
  require 'resolv'

  field :name, type: String
  field :priority, type: Integer, :default => 1
  field :weight, type: Integer, :default => 1
  field :ip, type: String
  field :enabled, type: Boolean, :default => true
  field :operational, type: Boolean, :default => true

  validates :name,  :uniqueness => { scope: :parent_a_record_id }, :if => :parent_is_domain?
  validates :ip, :presence => true, :format => { :with => Resolv::IPv4::Regex }

  belongs_to :parent_a_record, :polymorphic => true
  has_many :cluster_server_logs, :dependent => :destroy

  after_save :update_zone
  after_destroy :update_zone
  after_save :update_check_servers, :unless => :parent_is_domain?
  before_destroy :delete_from_check_servers, :unless => :parent_is_domain?

  # Call the update domain procedure when the record is saved or destroyed
  def update_zone
    self.parent_a_record.update_zone  unless self.parent_a_record.nil?
  end

  # Test uniqueness only if parent is a domain
  def parent_is_domain?
    self.parent_a_record.is_a?(Domain)
  end

  # Disable a service
  def disable_host
    self.operational = false
    self.save
  end

  # Enable a service
  def enable_host
    self.operational = true
    self.save
  end

  def update_check_servers
    Region.where(:has_check => true).each do |region|
      logger.debug region.code
      UpdateCheckWorker.perform_async(self.id.to_s,region.id.to_s)
    end
  end

  def delete_from_check_servers
    Region.where(:has_check => true).each do |region|
      logger.debug region.code
      DeleteCheckWorker.perform_async(self.id.to_s,region.id.to_s)
    end
  end
end
