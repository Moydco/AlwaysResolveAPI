# Attributes:
# - id: String, the local MX Record ID
# - name: String, the local MX name
# - priority: Integer, default 10, the SRV server priority
# - weight: Integer, default 0, the SRV server weight, in case of multiple server with same priority
# - port: Integer, default 80, the SRV server port
# - target: String, the alias host, must be present
# - enabled: Boolean, if is enabled or disabled (used by check server procedure)
# Relations:
# - belongs_to Domain

class SrvRecord
  include Mongoid::Document
  field :name, type: String
  field :priority, type: Integer, :default => 10
  field :weight, type: Integer, :default => 0
  field :port, type: Integer, :default => 80
  field :target, type: String
  field :enabled, type: Boolean, :default => true

  validates :target, :presence => true

  belongs_to :domain

  after_save :update_zone
  after_destroy :update_zone

  # Call the update domain procedure when the record is saved or destroyed
  def update_zone
    self.domain.update_zone unless self.domain.nil?
  end
end
