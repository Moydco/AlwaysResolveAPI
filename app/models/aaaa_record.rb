# Attributes:
# - id: String, the local AAAA Record ID
# - name: String, the local AAAA name, must be unique
# - priority: Integer, default 1, the priority in resolution when used in a cluster object
# - ip: String, the IP Address which resolves, must be a valid IPv6 address
# - enabled: Boolean, if is enabled or disabled (used by check server procedure)
# Relations:
# - belongs_to Domain
# - belongs_to GeoDns

class AaaaRecord
  include Mongoid::Document
  require 'resolv'

  field :name, type: String
  field :priority, type: Integer, :default => 1
  field :ip, type: String
  field :enabled, type: Boolean, :default => true

  validates :name,  :uniqueness => true
  validates :ip, :presence => true, :format => { :with => Resolv::IPv6::Regex }

  belongs_to :parent_aaaa_record, :polymorphic => true

  after_save :update_zone
  after_destroy :update_zone

  # Call the update domain procedure when the record is saved or destroyed
  def update_zone
    self.parent_aaaa_record.update_zone unless self.domain.nil?
  end
end
