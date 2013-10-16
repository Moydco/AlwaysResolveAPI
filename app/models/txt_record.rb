# Attributes:
# - id: String, the local TXT Record ID
# - name: String, the local TXT name, must be unique
# - value: String, the alias host, must be present
# - enabled: Boolean, if is enabled or disabled (used by check server procedure)
# Relations:
# - belongs_to Domain

class TxtRecord
  include Mongoid::Document
  field :name, type: String
  field :value, type: String
  field :enabled, type: Boolean, :default => true

  validates :name,  :uniqueness => true
  validates :value, :presence => true

  belongs_to :domain

  after_save :update_zone
  after_destroy :update_zone

  # Call the update domain procedure when the record is saved or destroyed
  def update_zone
    self.domain.update_zone
  end
end
