# Attributes:
# - id: String, the domain ID
# - zone: String, the zone name (ex. example.org). Must be unique
# Relations:
# - belongs_to User
# - has_one SoaRecord
# - has_many ARecord
# - has_many AaaaRecord
# - has_many CnameRecord
# - has_many MxRecord
# - has_many NsRecord
# - has_many TxtRecord
# - has_many Cluster

class Domain
  include Mongoid::Document
  field :zone, type: String

  belongs_to :user
  has_one :soa_record, :dependent => :destroy
  has_many :a_records,    :as => :parent_a_record, :dependent => :destroy
  has_many :aaaa_records, :as => :parent_aaaa_record, :dependent => :destroy
  has_many :cname_records, :dependent => :destroy
  has_many :mx_records, :dependent => :destroy
  has_many :ns_records, :dependent => :destroy
  has_many :txt_records, :dependent => :destroy

  has_many :clusters

  validates :zone,  :uniqueness => true

  after_create :create_default_records

  # Create default SOA and NS records
  def create_default_records
    self.zone_will_change!
    self.build_soa_record(:mname => Settings.ns01, :rname => Settings.email).save
    self.ns_records.build(:name => self.dot(self.zone), :value => Settings.ns01).save
    self.ns_records.build(:name => self.dot(self.zone), :value => Settings.ns02).save
    self.save!
  end

  # Update Serial SOA and DNS Servers
  def update_zone
    self.soa_record.update_serial unless self.soa_record.nil?
  end

  # Add dot at the end of zone
  def dot(z)
    return (z + '.')
  end

end
