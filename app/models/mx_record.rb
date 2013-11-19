# Attributes:
# - id: String, the local MX Record ID
# - name: String, the local MX name
# - priority: Integer, default 10, the MX server priority
# - value: String, the alias host, must be present
# - enabled: Boolean, if is enabled or disabled (used by check server procedure)
# Relations:
# - belongs_to Domain

class MxRecord
  include Mongoid::Document
  field :name, type: String
  field :priority, type: Integer, :default => 10
  field :value, type: String
  field :enabled, type: Boolean, :default => true

  validates :value, :presence => true

  belongs_to :domain

  after_save :update_zone
  after_destroy :update_zone

  # Call the update domain procedure when the record is saved or destroyed
  def update_zone
    self.domain.update_zone unless self.domain.nil?
  end
end
