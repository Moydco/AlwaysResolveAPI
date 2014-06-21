# Attributes:
# - id: String, the domain ID
# - zone: String, the zone name (ex. example.org). Must be unique
# - ttl: Integer, the default TTL for the zone (optional)
# Relations:
# - belongs_to User
# - has_many Record

class Domain
  include Mongoid::Document
  include Mongoid::Timestamps
  require "bunny"

  field :zone, type: String

  belongs_to :user
  has_many :records,     :dependent => :destroy

  attr_accessor :ttl, :st

  validates :zone,  :uniqueness => true,
                    :length => { maximum: 63 },
                    format: { :with => /\A([\-a-zA-Z0-9]+\.[\-a-zA-Z0-9]+)\z/ }

  validate :can_i_create_this_zone?

  before_validation :downcase_zone
  after_create :create_default_records
  before_destroy :delete_zone



  def downcase_zone
    self.zone.downcase unless self.zone.nil?
  end

  def can_i_create_this_zone?
    v = validates_property(self.zone)
    if !v.nil? and !v
      errors.add(:zone, "Master zone isn't yours")
    end

  end

  def validates_property(zone)
    #puts "Recived this zone: #{zone}"

    zone_splitted = zone.split('.')
    unless zone_splitted.empty?
      zone_splitted.shift
      new_zone = zone_splitted.join('.')
      puts "Now validating: #{new_zone}"
      if Domain.where(zone: new_zone).count == 1
        #puts 'this zone exists'
        #puts "the propietary is #{Domain.where(zone: new_zone).first.user}"
        #puts "I'm #{self.user}"
        return Domain.where(zone: new_zone).first.user == self.user
      else
        #puts 'Domain not found: trying another round'
        validates_property(new_zone)
      end
    end
  end

  # Create default SOA and NS records
  def create_default_records
    soa_record = self.records.create(name: '', type: 'SOA')
    if self.ttl.nil? or self.ttl.blank?
      soa_record.answers.build(:mname => Settings.ns01, :rname => Settings.email, :at => 60)
    else
      soa_record.answers.build(:mname => Settings.ns01, :rname => Settings.email, :at => self.ttl).save
    end
    soa_record.save
    soa_record.answers.first.update_serial
    ns_record = self.records.create(name: '', type: 'NS')
    ns_record.answers.build(:data => Settings.ns01)
    ns_record.answers.build(:data => Settings.ns02)
    ns_record.save
  end

  # Add dot at the end of zone
  def dot(z)
    return (z + '.')
  end

  # check the record name and, if is empty, return the zone name
  def record_name(record)
    if record.nil? or record.blank?
      return dot(self.zone).downcase
    else
      return record.downcase
    end
  end

  # Update data in all DNS servers via RabbitMQ
  def update_zone
    send_to_rabbit(:update)
  end

  # Delete zone in all DNS servers via RabbitMQ
  def delete_zone
    send_to_rabbit(:delete)
  end

  # Send the zone to RabbitMQ servers four update
  def send_to_rabbit(action)
    Region.where(has_dns: true).each do |region|

      conn = Bunny.new(:host => region.dns_ip_address)
      conn.start

      ch   = conn.create_channel
      q    = ch.fanout("moyd")
      # q.publish("delete+#{dot(self.zone)}", :routing_key => q.name)
      # q.publish("data+#{self.json_zone(region.id.to_s)}")
      if action == :update
        if Settings.zone_details_in_update.downcase == 'false'
          q.publish("update+#{self.zone}")
        else
          q.publish("data+#{json_zone(region.id)}")
        end
      elsif action == :delete
        q.publish("delete+#{dot(self.zone)}", :routing_key => q.name)
      end
      #ch.default_exchange.publish("data+{\"origin\":\"pippo.com.\",\"ttl\":10,\"NS\":[{\"class\":\"in\",\"name\":\"pippo.com.\",\"value\":[{\"weight\":1,\"ns\":\"ns01.moyd.co\"},{\"weight\":1,\"ns\":\"ns02.moyd.co\"}]}],\"SOA\":[{\"class\":\"in\",\"name\":\"pippo.com.\",\"mname\":\"ns01.moyd.co\",\"rname\":\"domains@moyd.co\",\"at\":\"1M\",\"serial\":2013101700,\"refresh\":\"1M\",\"retry\":\"1M\",\"expire\":\"1M\",\"minimum\":\"1M\"}],\"A\":[{\"class\":\"in\",\"name\":\"atest\",\"value\":[{\"weight\":1,\"ip\":\"192.168.2.1\"}]},{\"class\":\"in\",\"name\":\"ha1\",\"value\":[{\"weight\":1,\"ip\":\"192.168.0.1\"},{\"weight\":null,\"ip\":\"192.168.0.2\"},{\"weight\":2,\"ip\":\"192.168.0.3\"}]}]}", :routing_key => q.name)
      conn.close
    end
  end

  def record_last_level(fqdn)
    return fqdn.split('.').first.downcase
  end

  def zone_name(fqdn)
    levels = fqdn.split('.')
    levels.delete(levels.first)
    return levels.join('.').downcase
  end

  def resolve_alias(record)
    if not record.nil? and record.enabled and record.operational and record.alias
      resolve_alias(Domain.where(zone: zone_name(record.answers.first.data)).first.records.where(name: record_last_level(record.answers.first.data), enabled: true, operational: true).first)
    else
      if not record.nil? and record.enabled and record.operational
        return record
      else
        return nil
      end
    end
  end

  def set_ttl(record)
    if record.ttl.nil? or record.ttl.blank?
      return self.records.where(type: 'SOA').first.at
    else
      return record.ttl
    end
  end

  # Create the JSON of the zone:
  def json_zone(region_id)
    if region_id.nil?
      region = nil
    else
      region = Region.find(region_id)
    end

    soa_record= self.records.where(:enabled => true, :operational => true, :type => 'SOA').first.answers.first
    soa_record.update_serial

    Jbuilder.encode do |json|
      json.origin dot(self.zone.downcase)
      json.ttl soa_record.at.to_i


      # SOA

      if self.records.where(:enabled => true, :operational => true, :type => 'SOA').exists?
        json.SOA do |json|
          json.child! do |json|
            json.class "in"
            json.name dot(self.zone.downcase)
            json.mname soa_record.mname
            json.rname soa_record.rname
            json.at soa_record.at
            json.serial soa_record.serial
            json.refresh soa_record.refresh
            json.retry soa_record.retry
            json.expire soa_record.expire
            json.minimum soa_record.minimum
          end
        end
      end


      # NS

      if self.records.where(:enabled => true, :operational => true, :type => 'NS').exists?
        json.NS do |json|
          self.records.where(:enabled => true, :operational => true, :type => 'NS').map(&:name).uniq.each do |ns_name|
            self.records.where(:enabled => true, :operational => true, :type => 'NS', :name => ns_name).each do |record|
              json.child! do|json|
                json.class "in"
                json.name record_name(ns_name)
                json.ttl self.set_ttl(record)
                json.value record.answers.each do |answer|
                  json.weight 1
                  json.ns answer.data
                end
              end
            end
          end
        end
      end

      ## MX

      if self.records.where(:enabled => true, :operational => true, :type => 'MX').exists?
        json.MX do |json|
          self.records.where(:enabled => true, :operational => true, :type => 'MX').map(&:name).uniq.each do |mx_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :type => 'MX', :name => mx_name).first.routing_policy
            if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
              self.records.where(:enabled => true, :operational => true, :type => 'MX', :name => mx_name).each do |record|
                record = resolve_alias(record)
                  unless record.nil?
                  record.answers.each do |answer|
                    json.child! do|json|
                      json.class "in"
                      json.ttl self.set_ttl(record)
                      json.name record_name(mx_name)
                      json.priority answer.priority
                      json.value answer.data
                    end
                  end
                end
              end
            elsif routing_policy == 'LATENCY'
              if self.records.where(:enabled => true, :operational => true, :type => 'MX', :name => mx_name, :region => region).exists?
                self.records.where(:enabled => true, :operational => true, :type => 'MX', :name => mx_name, :region => region).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    record.answers.each do |answer|
                      json.child! do|json|
                        json.class "in"
                        json.ttl self.set_ttl(record)
                        json.name record_name(mx_name)
                        json.priority answer.priority
                        json.value answer.data
                      end
                    end
                  end
                end
              else
                found = false
                region.neighbor_regions.order_by(:proximity => :asc).each do |n|
                  unless found
                    if self.records.where(:enabled => true, :operational => true, :type => 'MX', :name => mx_name, :region => n.neighbor).exists?
                      found = true
                      self.records.where(:enabled => true, :operational => true, :type => 'MX', :name => mx_name, :region => n.neighbor).each do |record|
                        record = resolve_alias(record)
                        unless record.nil?
                          record.answers.each do |answer|
                            json.child! do|json|
                              json.class "in"
                              json.ttl self.set_ttl(record)
                              json.name record_name(mx_name)
                              json.priority answer.priority
                              json.value answer.data
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            elsif  routing_policy == 'FAILOVER'
              if self.records.where(:enabled => true, :operational => true, :type => 'MX', :name => mx_name, :primary => true).exists?
                self.records.where(:enabled => true, :operational => true, :type => 'MX', :name => mx_name, :primary => true).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    record.answers.each do |answer|
                      json.child! do|json|
                        json.class "in"
                        json.ttl self.set_ttl(record)
                        json.name record_name(mx_name)
                        json.priority answer.priority
                        json.value answer.data
                      end
                    end
                  end
                end
              else
                self.records.where(:enabled => true, :operational => true, :type => 'MX', :name => mx_name, :primary => false).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    record.answers.each do |answer|
                      json.child! do|json|
                        json.class "in"
                        json.ttl self.set_ttl(record)
                        json.name record_name(mx_name)
                        json.priority answer.priority
                        json.value answer.data
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      ## CNAME

      if self.records.where(:enabled => true, :operational => true, :type => 'CNAME').exists?
        json.CNAME do |json|
          self.records.where(:enabled => true, :operational => true, :type => 'CNAME').map(&:name).uniq.each do |cname_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :type => 'CNAME', :name => cname_name).first.routing_policy
            if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
              self.records.where(:enabled => true, :operational => true, :type => 'CNAME', :name => cname_name).each do |record|
                record = resolve_alias(record)
                unless record.nil?
                  answer = record.answers.first
                  json.child! do|json|
                    json.class "in"
                    json.ttl self.set_ttl(record)
                    json.name record_name(cname_name)
                    json.value answer.data
                  end
                end
              end
            elsif routing_policy == 'LATENCY'
              if self.records.where(:enabled => true, :operational => true, :type => 'CNAME', :name => cname_name, :region => region).exists?
                self.records.where(:enabled => true, :operational => true, :type => 'CNAME', :name => cname_name, :region => region).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    answer = record.answers.first
                    json.child! do|json|
                      json.class "in"
                      json.ttl self.set_ttl(record)
                      json.name record_name(cname_name)
                      json.value answer.data
                    end
                  end
                end
              else
                found = false
                region.neighbor_regions.order_by(:proximity => :asc).each do |n|
                  unless found
                    if self.records.where(:enabled => true, :operational => true, :type => 'CNAME', :name => cname_name, :region => n.neighbor).exists?
                      found = true
                      self.records.where(:enabled => true, :operational => true, :type => 'CNAME', :name => cname_name, :region => n.neighbor).each do |record|
                        record = resolve_alias(record)
                        unless record.nil?
                          answer = record.answers.first
                          json.child! do|json|
                            json.class "in"
                            json.ttl self.set_ttl(record)
                            json.name record_name(cname_name)
                            json.value answer.data
                          end
                        end
                      end
                    end
                  end
                end
              end
            elsif  routing_policy == 'FAILOVER'
              if self.records.where(:enabled => true, :operational => true, :type => 'CNAME', :name => cname_name, :primary => true).exists?
                self.records.where(:enabled => true, :operational => true, :type => 'CNAME', :name => cname_name, :primary => true).each do |record|
                  record = resolve_alias(record)
                  answer = record.answers.first
                  unless record.nil?
                    json.child! do|json|
                      json.class "in"
                      json.ttl self.set_ttl(record)
                      json.name record_name(cname_name)
                      json.value answer.data
                    end
                  end
                end
              else
                self.records.where(:enabled => true, :operational => true, :type => 'CNAME', :name => cname_name, :primary => false).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    answer = record.answers.first
                    json.child! do|json|
                      json.class "in"
                      json.ttl self.set_ttl(record)
                      json.name record_name(cname_name)
                      json.value answer.data
                    end
                  end
                end
              end
            end
          end
        end
      end


      ## A

      if self.records.where(:enabled => true, :operational => true, :type => 'A').exists?
        json.A do |json|
          self.records.where(:enabled => true, :operational => true, :type => 'A').map(&:name).uniq.each do |a_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name).first.routing_policy
            json.child! do|json|
              json.class "in"
              json.name record_name(a_name)
              answers = []
              if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
                single = false
                single = true if self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name).count == 1
                self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    record.answers.each do |answer|
                      if single
                        answers.push(weight: 1, ip: answer.ip)
                      else
                        answers.push(weight: record.weight, ip: answer.ip)
                      end
                    end
                    json.ttl self.set_ttl(record)
                  end
                end
                json.value answers.each do |answer|
                  json.weight answer[:weight]
                  json.ip answer[:ip]
                end
              elsif routing_policy == 'LATENCY'
                if self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name, :region => region).exists?
                  self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name, :region => region).each do |record|
                    record = resolve_alias(record)
                    unless record.nil?
                      record.answers.each do |answer|
                        answers.push(weight: 1, ip: answer.ip)
                      end
                      json.ttl self.set_ttl(record)
                    end
                  end
                  json.value answers.each do |answer|
                    json.weight answer[:weight]
                    json.ip answer[:ip]
                  end
                else
                  found = false
                  region.neighbor_regions.order_by(:proximity => :asc).each do |n|
                    unless found
                      if self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name, :region => n.neighbor).exists?
                        found = true
                        self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name, :region => n.neighbor).each do |record|
                          record = resolve_alias(record)
                          unless record.nil?
                            record.answers.each do |answer|
                              answers.push(weight: 1, ip: answer.ip)
                            end
                            json.ttl self.set_ttl(record)
                          end
                        end
                        json.value answers.each do |answer|
                          json.weight answer[:weight]
                          json.ip answer[:ip]
                        end
                      end
                    end
                  end
                end
              elsif  routing_policy == 'FAILOVER'
                if self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name, :primary => true).exists?
                  self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name, :primary => true).each do |record|
                    record = resolve_alias(record)
                    unless record.nil?
                      record.answers.each do |answer|
                        answers.push(weight: 1, ip: answer.ip)
                      end
                      json.ttl self.set_ttl(record)
                    end
                  end
                  json.value answers.each do |answer|
                    json.weight answer[:weight]
                    json.ip answer[:ip]
                  end
                else
                  self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name, :primary => false).each do |record|
                    record = resolve_alias(record)
                    unless record.nil?
                      record.answers.each do |answer|
                        answers.push(weight: 1, ip: answer.ip)
                      end
                      json.ttl self.set_ttl(record)
                    end
                  end
                  json.value answers.each do |answer|
                    json.weight answer[:weight]
                    json.ip answer[:ip]
                  end
                end
              end
            end
          end
        end
      end


      ## AAAA

      if self.records.where(:enabled => true, :operational => true, :type => 'AAAA').exists?
        json.AAAA do |json|
          self.records.where(:enabled => true, :operational => true, :type => 'AAAA').map(&:name).uniq.each do |aaaa_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :type => 'AAAA', :name => aaaa_name).first.routing_policy
            json.child! do|json|
              json.class "in"
              json.name record_name(aaaa_name)
              answers = []
              if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
                single = false
                single = true if self.records.where(:enabled => true, :operational => true, :type => 'A', :name => a_name).count == 1
                self.records.where(:enabled => true, :operational => true, :type => 'AAAA', :name => aaaa_name).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    record.answers.each do |answer|
                      if single
                        answers.push(weight: 1, ip: answer.ip)
                      else
                        answers.push(weight: record.weight, ip: answer.ip)
                      end
                    end
                    json.ttl self.set_ttl(record)
                  end
                end
                json.value answers.each do |answer|
                  json.weight answer[:weight]
                  json.ip answer[:ip]
                end
              elsif routing_policy == 'LATENCY'
                if self.records.where(:enabled => true, :operational => true, :type => 'AAAA', :name => aaaa_name, :region => region).exists?
                  self.records.where(:enabled => true, :operational => true, :type => 'AAAA', :name => aaaa_name, :region => region).each do |record|
                    record = resolve_alias(record)
                    unless record.nil?
                      record.answers.each do |answer|
                        answers.push(weight: 1, ip: answer.ip)
                      end
                      json.ttl self.set_ttl(record)
                    end
                  end
                  json.value answers.each do |answer|
                    json.weight answer[:weight]
                    json.ip answer[:ip]
                  end
                else
                  found = false
                  region.neighbor_regions.order_by(:proximity => :asc).each do |n|
                    unless found
                      if self.records.where(:enabled => true, :operational => true, :type => 'AAAA', :name => aaaa_name, :region => n.neighbor).exists?
                        found = true
                        self.records.where(:enabled => true, :operational => true, :type => 'AAAA', :name => aaaa_name, :region => n.neighbor).each do |record|
                          record = resolve_alias(record)
                          unless record.nil?
                            record.answers.each do |answer|
                              answers.push(weight: 1, ip: answer.ip)
                            end
                            json.ttl self.set_ttl(record)
                          end
                        end
                        json.value answers.each do |answer|
                          json.weight answer[:weight]
                          json.ip answer[:ip]
                        end
                      end
                    end
                  end
                end
              elsif  routing_policy == 'FAILOVER'
                if self.records.where(:enabled => true, :operational => true, :type => 'AAAA', :name => aaaa_name, :primary => true).exists?
                  self.records.where(:enabled => true, :operational => true, :type => 'AAAA', :name => aaaa_name, :primary => true).each do |record|
                    record = resolve_alias(record)
                    unless record.nil?
                      record.answers.each do |answer|
                        answers.push(weight: 1, ip: answer.ip)
                      end
                      json.ttl self.set_ttl(record)
                    end
                  end
                  json.value answers.each do |answer|
                    json.weight answer[:weight]
                    json.ip answer[:ip]
                  end
                else
                  self.records.where(:enabled => true, :operational => true, :type => 'AAAA', :name => aaaa_name, :primary => false).each do |record|
                    record = resolve_alias(record)
                    unless record.nil?
                      record.answers.each do |answer|
                        answers.push(weight: 1, ip: answer.ip)
                      end
                      json.ttl self.set_ttl(record)
                    end
                  end
                  json.value answers.each do |answer|
                    json.weight answer[:weight]
                    json.ip answer[:ip]
                  end
                end
              end
            end
          end
        end
      end


      ## SRV

      if self.records.where(:enabled => true, :operational => true, :type => 'SRV').exists?
        json.SRV do |json|
          self.records.where(:enabled => true, :operational => true, :type => 'SRV').map(&:name).uniq.each do |srv_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :type => 'SRV', :name => srv_name).first.routing_policy
            if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
              self.records.where(:enabled => true, :operational => true, :type => 'SRV', :name => srv_name).each do |record|
                record = resolve_alias(record)
                unless record.nil?
                  answer = record.answers.first
                  json.child! do|json|
                    json.class "in"
                    json.ttl self.set_ttl(record)
                    json.name record_name(srv_name)
                    json.priority answer.priority
                    json.weight answer.weight
                    json.port answer.port
                    json.target answer.data
                  end
                end
              end
            elsif routing_policy == 'LATENCY'
              if self.records.where(:enabled => true, :operational => true, :type => 'SRV', :name => srv_name, :region => region).exists?
                self.records.where(:enabled => true, :operational => true, :type => 'SRV', :name => srv_name, :region => region).each do |record|
                  record = resolve_alias(record)
                  answer = record.answers.first
                  unless record.nil?
                    json.child! do|json|
                      json.class "in"
                      json.ttl self.set_ttl(record)
                      json.name record_name(srv_name)
                      json.priority answer.priority
                      json.weight answer.weight
                      json.port answer.port
                      json.target answer.data
                    end
                  end
                end
              else
                found = false
                region.neighbor_regions.order_by(:proximity => :asc).each do |n|
                  unless found
                    if self.records.where(:enabled => true, :operational => true, :type => 'SRV', :name => srv_name, :region => n.neighbor).exists?
                      found = true
                      self.records.where(:enabled => true, :operational => true, :type => 'SRV', :name => srv_name, :region => n.neighbor).each do |record|
                        record = resolve_alias(record)
                        unless record.nil?
                          answer = record.answers.first
                          json.child! do|json|
                            json.class "in"
                            json.ttl self.set_ttl(record)
                            json.name record_name(srv_name)
                            json.priority answer.priority
                            json.weight answer.weight
                            json.port answer.port
                            json.target answer.data
                          end
                        end
                      end
                    end
                  end
                end
              end
            elsif  routing_policy == 'FAILOVER'
              if self.records.where(:enabled => true, :operational => true, :type => 'SRV', :name => srv_name, :primary => true).exists?
                self.records.where(:enabled => true, :operational => true, :type => 'SRV', :name => srv_name, :primary => true).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    answer = record.answers.first
                    json.child! do|json|
                      json.class "in"
                      json.ttl self.set_ttl(record)
                      json.name record_name(srv_name)
                      json.priority answer.priority
                      json.weight answer.weight
                      json.port answer.port
                      json.target answer.data
                    end
                  end
                end
              else
                self.records.where(:enabled => true, :operational => true, :type => 'SRV', :name => srv_name, :primary => false).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    answer = record.answers.first
                    json.child! do|json|
                      json.class "in"
                      json.ttl self.set_ttl(record)
                      json.name record_name(srv_name)
                      json.priority answer.priority
                      json.weight answer.weight
                      json.port answer.port
                      json.target answer.data
                    end
                  end
                end
              end
            end
          end
        end
      end

      ## TXT

      if self.records.where(:enabled => true, :operational => true, :type => 'TXT').exists?
        json.TXT do |json|
          self.records.where(:enabled => true, :operational => true, :type => 'TXT').map(&:name).uniq.each do |txt_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :type => 'TXT', :name => txt_name).first.routing_policy
            if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
              self.records.where(:enabled => true, :operational => true, :type => 'TXT', :name => txt_name).each do |record|
                record = resolve_alias(record)
                unless record.nil?
                  answer =  record.answers.first
                  json.child! do|json|
                    json.class "in"
                    json.ttl self.set_ttl(record)
                    json.name record_name(txt_name)
                    json.value do |json|
                      json.array! [answer.data]
                    end
                  end
                end
              end
            elsif routing_policy == 'LATENCY'
              if self.records.where(:enabled => true, :operational => true, :type => 'TXT', :name => txt_name, :region => region).exists?
                self.records.where(:enabled => true, :operational => true, :type => 'TXT', :name => txt_name, :region => region).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    answer = record.answers.first
                    json.child! do|json|
                      json.class "in"
                      json.ttl self.set_ttl(record)
                      json.name record_name(txt_name)
                      json.value do |json|
                        json.array! [answer.data]
                      end
                    end
                  end
                end
              else
                found = false
                region.neighbor_regions.order_by(:proximity => :asc).each do |n|
                  unless found
                    if self.records.where(:enabled => true, :operational => true, :type => 'TXT', :name => txt_name, :region => n.neighbor).exists?
                      found = true
                      self.records.where(:enabled => true, :operational => true, :type => 'TXT', :name => txt_name, :region => n.neighbor).each do |record|
                        record = resolve_alias(record)
                        unless record.nil?
                          answer = record.answers.first
                          json.child! do|json|
                            json.class "in"
                            json.ttl self.set_ttl(record)
                            json.name record_name(txt_name)
                            json.value do |json|
                              json.array! [answer.data]
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            elsif  routing_policy == 'FAILOVER'
              if self.records.where(:enabled => true, :operational => true, :type => 'TXT', :name => txt_name, :primary => true).exists?
                self.records.where(:enabled => true, :operational => true, :type => 'TXT', :name => txt_name, :primary => true).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    answer = record.answers.first
                    json.child! do|json|
                      json.class "in"
                      json.ttl self.set_ttl(record)
                      json.name record_name(txt_name)
                      json.value do |json|
                        json.array! [answer.data]
                      end
                    end
                  end
                end
              else
                self.records.where(:enabled => true, :operational => true, :type => 'TXT', :name => txt_name, :primary => false).each do |record|
                  record = resolve_alias(record)
                  unless record.nil?
                    answer = record.answers.first
                    json.child! do|json|
                      json.class "in"
                      json.ttl self.set_ttl(record)
                      json.name record_name(txt_name)
                      json.value do |json|
                        json.array! [answer.data]
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      # PTR

      if self.records.where(:enabled => true, :operational => true, :type => 'PTR').exists?
        json.PTR do |json|
          self.records.where(:enabled => true, :operational => true, :type => 'PTR').map(&:name).uniq.each do |ptr_name|
            self.records.where(:enabled => true, :operational => true, :type => 'PTR', :name => ptr_name).each do |record|
              record = resolve_alias(record)
              unless record.nil?
                answer = record.answers.first
                json.child! do|json|
                  json.class "in"
                  json.ttl self.set_ttl(record)
                  json.name record_name(ptr_name)
                  json.value answer.data
                end
              end
            end
          end
        end
      end
    end
  end
end
