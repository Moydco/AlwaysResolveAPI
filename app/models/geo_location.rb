# Attributes:
# - id: String, the local GeoDns Record ID
# - enabled: Boolean, if is enabled or disabled (used by check server procedure)
# Relations:
# - belongs_to Cluster
# - belongs_to Region
# - has_many ARecord
# - has_many AaaaRecord

class GeoLocation
  include Mongoid::Document
  field :enabled, type: Boolean, :default => true

  belongs_to :cluster
  belongs_to :region
  has_many :a_records,    :as => :parent_a_record, :dependent => :destroy
  has_many :aaaa_records, :as => :parent_aaaa_record, :dependent => :destroy

  # Call the update domain procedure when the record is saved or destroyed
  def update_zone
    self.cluster.domain.update_zone if !self.cluster.nil? and !self.cluster.domain.nil?
  end

end
