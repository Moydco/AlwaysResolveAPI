# Attributes:
# - id: String, the local GeoDns Record ID
# - region: String, the region associated to these IP Address. Empty for default
# - enabled: Boolean, if is enabled or disabled (used by check server procedure)
# Relations:
# - belongs_to Cluster
# - has_many ARecord
# - has_many AaaaRecord

class GeoLocation
  include Mongoid::Document
  field :region, type: String, :default => 'default'
  field :enabled, type: Boolean, :default => true

  belongs_to :cluster
  has_many :a_records,    :as => :parent_a_record, :dependent => :destroy
  has_many :aaaa_records, :as => :parent_aaaa_record, :dependent => :destroy

  validates :region,  :uniqueness => { scope: :cluster_id }

  # Call the update domain procedure when the record is saved or destroyed
  def update_zone
    self.cluster.domain.update_zone if !self.cluster.nil? and !self.cluster.domain.nil?
  end

end
