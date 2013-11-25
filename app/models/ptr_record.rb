# Attributes:
# - id: String, the local PTR Record ID
# - ip: String, the IP Address which resolves
# - value: String, the local A name, must be unique
# - enabled: Boolean, if is enabled or disabled
# Relations:
# - belongs_to Domain

class PtrRecord
  include Mongoid::Document
  require 'resolv'

  field :value, type: String
  field :ip, type: String
  field :enabled, type: Boolean, :default => true

  validates :value, :presence => true
  validates :ip, :presence => true,  :uniqueness => { scope: :domain_id }

  belongs_to :domain

  after_save :update_zone
  after_destroy :update_zone

  # Call the update domain procedure when the record is saved or destroyed
  def update_zone
    self.domain.update_zone  unless self.domain.nil?
  end

end
