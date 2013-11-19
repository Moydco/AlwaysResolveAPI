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
  require "bunny"

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
    # now I update all RabbitMQ servers
    send_to_rabbit
  end

  # Add dot at the end of zone
  def dot(z)
    return (z + '.')
  end

  # Create the JSON of the zone:
  def json_zone(region)
    Jbuilder.encode do |json|
      json.origin dot(self.zone)
      json.ttl 10

      if self.ns_records.where(:enabled => true).exists?
        json.NS do |json|
          self.ns_records.where(:enabled => true).map(&:name).uniq.each do |ns_name|
            json.child! do|json|
              json.class "in"
              json.name ns_name
              json.value ns_records.where(:name => ns_name).each do |record|
                json.weight 1
                json.ns record.value
              end
            end
          end
        end
      end

      unless self.soa_record.nil?
        json.SOA do |json|
          json.child! do |json|
            json.class "in"
            json.name dot(self.zone)
            json.mname self.soa_record.mname
            json.rname self.soa_record.rname
            json.at self.soa_record.at
            json.serial self.soa_record.serial
            json.refresh self.soa_record.refresh
            json.retry self.soa_record.retry
            json.expire self.soa_record.expire
            json.minimum self.soa_record.minimum
          end
        end
      end

      if self.cname_records.where(:enabled => true).exists?
        json.CNAME do |json|
          self.cname_records.where(:enabled => true).uniq.each do |cname|
            json.child! do|json|
              json.class "in"
              json.name record_name(cname.name)
              json.value cname.value
            end
          end
        end
      end

      if self.mx_records.where(:enabled => true).exists?
        json.MX do |json|
          self.mx_records.where(:enabled => true).uniq.each do |mx|
            json.child! do|json|
              json.class "in"
              json.name record_name(mx.name)
              json.priority mx.priority
              json.value mx.value
            end
          end
        end
      end

      if self.txt_records.where(:enabled => true).exists?
        json.TXT do |json|
          self.txt_records.where(:enabled => true).uniq.each do |txt|
            json.child! do|json|
              json.class "in"
              json.name record_name(txt.name)
              json.value do |json|
                json.array! [txt.value]
              end
            end
          end
        end
      end

      a_records_name = (self.a_records.where(:enabled => true).map(&:name) + self.clusters.where(:enabled => true).map(&:name)).uniq

      if a_records_name.count > 0
        json.A do |json|
          a_records_name.each do |a_name|
            json.child! do|json|
              json.class "in"
              json.name record_name(a_name)
              if self.a_records.where(:name => a_name).exists?
                # is an A record
                json.value a_records.where(:name => a_name).each do |record|
                  if record.priority.nil?
                    json.weight 1
                  else
                    json.weight record.priority
                  end
                  json.ip record.ip
                end
              elsif self.clusters.where(:name => a_name).exists?
                cluster=self.clusters.where(:name => a_name).first
                if cluster.type == 'HA'
                  if cluster.geo_locations.where(:region => 'default').first.a_records.where(:name => a_name, :operational => true, :enabled => true).order_by(:priority => :asc).exists?
                    json.value cluster.geo_locations.where(:region => 'default').first.a_records.where(:name => a_name, :operational => true, :enabled => true).order_by(:priority => :asc).limit(1) do |record|
                      if record.weight.nil?
                        json.weight 1
                      else
                        json.weight record.weight
                      end
                      json.ip record.ip
                    end
                  else
                    json.value do |json|
                      json.weight 1
                      json.ip '127.0.0.1'
                    end
                  end
                elsif cluster.type == 'LB'
                  json.value cluster.geo_locations.where(:region => 'default').first.a_records.where(:name => a_name, :operational => true, :enabled => true).each do |record|
                    if record.weight.nil?
                      json.weight 1
                    else
                      json.weight record.weight
                    end
                    json.ip record.ip
                  end
                elsif cluster.type == 'GEO'
                  if cluster.geo_locations.where(:region => region).exists?
                    json.value cluster.geo_locations.where(:region => region).first.a_records.where(:name => a_name, :operational => true, :enabled => true).each do |record|
                      if record.weight.nil?
                        json.weight 1
                      else
                        json.weight record.weight
                      end
                      json.ip record.ip
                    end
                  else
                    json.value cluster.geo_locations.where(:region => 'default').first.a_records.where(:name => a_name, :operational => true, :enabled => true).each do |record|
                      if record.weight.nil?
                        json.weight 1
                      else
                        json.weight record.weight
                      end
                      json.ip record.ip
                    end
                  end
                end
              end
            end
          end
        end
      end

      if self.aaaa_records.where(:enabled => true).exists?
        json.AAAA do |json|
          self.aaaa_records.where(:enabled => true).map(&:name).uniq.each do |aaaa_name|
            json.child! do|json|
              json.class "in"
              json.name record_name(aaaa_name)
              json.value aaaa_records.where(:name => aaaa_name).each do |record|
                json.weight record.priority
                json.ip record.ip
              end
            end
          end
        end
      end
    end
  end

  # Send the zone to RabbitMQ servers four update
  def send_to_rabbit
    Region.each do |region|
      conn = Bunny.new(:host => region.ip_address)
      conn.start

      ch   = conn.create_channel
      q    = ch.fanout("moyd")
      q.publish("delete+#{dot(self.zone)}", :routing_key => q.name)
      q.publish("data+#{self.json_zone(region.code)}")

      #ch.default_exchange.publish("data+{\"origin\":\"pippo.com.\",\"ttl\":10,\"NS\":[{\"class\":\"in\",\"name\":\"pippo.com.\",\"value\":[{\"weight\":1,\"ns\":\"ns01.moyd.co\"},{\"weight\":1,\"ns\":\"ns02.moyd.co\"}]}],\"SOA\":[{\"class\":\"in\",\"name\":\"pippo.com.\",\"mname\":\"ns01.moyd.co\",\"rname\":\"domains@moyd.co\",\"at\":\"1M\",\"serial\":2013101700,\"refresh\":\"1M\",\"retry\":\"1M\",\"expire\":\"1M\",\"minimum\":\"1M\"}],\"A\":[{\"class\":\"in\",\"name\":\"atest\",\"value\":[{\"weight\":1,\"ip\":\"192.168.2.1\"}]},{\"class\":\"in\",\"name\":\"ha1\",\"value\":[{\"weight\":1,\"ip\":\"192.168.0.1\"},{\"weight\":null,\"ip\":\"192.168.0.2\"},{\"weight\":2,\"ip\":\"192.168.0.3\"}]}]}", :routing_key => q.name)
      conn.close
    end
  end

  # check the record name and, if is empty, return the zone name
  def record_name(record)
    if record.nil? or record.blank?
      return dot(self.zone)
    else
      return record
    end
  end
end
