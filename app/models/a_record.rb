# Attributes:
# - id: String, the local A Record ID
# - name: String, the local A name, must be unique
# - priority: Integer, default 1, the priority in resolution when used in a HA cluster object (small number = high priority)
# - weight: Integer, default 1, the weight in resolution when used in a LB cluster object (small number = small weight)
# - ip: String, the IP Address which resolves, must be a valid IPv4 address
# - enabled: Boolean, if is enabled or disabled
# - operational: Boolean, if is enabled or disabled (used by check server procedure)
# Relations:
# - belongs_to Domain
# - belongs_to GeoDns

class ARecord
  include Mongoid::Document
  require 'resolv'

  field :name, type: String
  field :priority, type: Integer, :default => 1
  field :weight, type: Integer, :default => 1
  field :ip, type: String
  field :enabled, type: Boolean, :default => true
  field :operational, type: Boolean, :default => true

  validates :name,  :uniqueness => { scope: :parent_a_record_id }, :if => :condition_testing?
  validates :ip, :presence => true, :format => { :with => Resolv::IPv4::Regex }

  belongs_to :parent_a_record, :polymorphic => true

  after_save :update_zone
  after_destroy :update_zone

  # Call the update domain procedure when the record is saved or destroyed
  def update_zone
    self.parent_a_record.update_zone  unless self.parent_a_record.nil?
  end

  # Test uniqueness only if parent is a domain
  def condition_testing?
    self.parent_a_record.is_a?(Domain)
  end
end
