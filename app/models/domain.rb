# --------------------------------------------------------------------------- #
# Copyright 2013-2015, AlwaysResolve Project (alwaysresolve.org), MOYD.CO LTD #
#                                                                             #
# Licensed under the Apache License, Version 2.0 (the "License"); you may     #
# not use this file except in compliance with the License. You may obtain     #
# a copy of the License at                                                    #
#                                                                             #
# http://www.apache.org/licenses/LICENSE-2.0                                  #
#                                                                             #
# Unless required by applicable law or agreed to in writing, software         #
# distributed under the License is distributed on an "AS IS" BASIS,           #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    #
# See the License for the specific language governing permissions and         #
# limitations under the License.                                              #
# --------------------------------------------------------------------------- #


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
  field :last_bill, type: Date, default: Date.today
  field :admin_enabled, type: Boolean, default: true

  belongs_to :user
  has_many :records,     :dependent => :destroy
  has_many :domain_statistics
  has_many :domain_monthly_stats


  attr_accessor :ttl, :st

  validates :zone,  :uniqueness => true,
                    :length => { maximum: 63 },
                    format: { :with => /\A([\.\-a-zA-Z0-9]+\.[\-a-zA-Z0-9]+)\z/ }

  validate :can_i_create_this_zone?

  before_validation :downcase_zone
  before_create :new_domain_callback

  after_create :create_default_records
  before_destroy :delete_zone


  def new_domain_callback
    unless Settings.callback_new_domain == '' or Settings.callback_new_domain.nil?
      url_to_call = Settings.callback_new_domain + '/?format=json'
      url_to_call.sub!(':user', self.user.user_reference.partition('-').first) if url_to_call.include? ':user'
      url = URI.parse(url_to_call)

      amount = (Date.today.end_of_month - Date.today).to_i * (Settings.domain_monthly_amount.to_f / 30)

      if Settings.callback_method == 'POST'
        req = Net::HTTP::Post.new(url.path)
      else
        req = Net::HTTP::Get.new(url.path)
      end

      if Settings.auth_method == 'oauth2'
        req.set_form_data({amount: amount, client_id: Settings.oauth2_id, client_secret: Settings.oauth2_secret})
      else
        req.set_form_data({amount: amount})
      end
      sock = Net::HTTP.new(url.host, url.port)
      if Settings.callback_new_domain.starts_with? 'https'
        sock.use_ssl = true
        sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      response=sock.start {|http| http.request(req) }

      response.code.to_i == 200
    end
  end

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
    ns_record.answers.build(:data => Settings.ns03) unless Settings.ns03.empty?
    ns_record.answers.build(:data => Settings.ns04) unless Settings.ns04.empty?
    ns_record.answers.build(:data => Settings.ns05) unless Settings.ns05.empty?
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
      send_to_local_rabbit(action,region)
    end
  end

  def send_to_local_rabbit(action,region)
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
        q.publish("update+#{json_zone(region.id)}")
      end
    elsif action == :delete
      q.publish("delete+#{dot(self.zone)}", :routing_key => q.name)
    end
    #ch.default_exchange.publish("data+{\"origin\":\"pippo.com.\",\"ttl\":10,\"NS\":[{\"class\":\"in\",\"name\":\"pippo.com.\",\"value\":[{\"weight\":1,\"ns\":\"ns01.moyd.co\"},{\"weight\":1,\"ns\":\"ns02.moyd.co\"}]}],\"SOA\":[{\"class\":\"in\",\"name\":\"pippo.com.\",\"mname\":\"ns01.moyd.co\",\"rname\":\"domains@moyd.co\",\"at\":\"1M\",\"serial\":2013101700,\"refresh\":\"1M\",\"retry\":\"1M\",\"expire\":\"1M\",\"minimum\":\"1M\"}],\"A\":[{\"class\":\"in\",\"name\":\"atest\",\"value\":[{\"weight\":1,\"ip\":\"192.168.2.1\"}]},{\"class\":\"in\",\"name\":\"ha1\",\"value\":[{\"weight\":1,\"ip\":\"192.168.0.1\"},{\"weight\":null,\"ip\":\"192.168.0.2\"},{\"weight\":2,\"ip\":\"192.168.0.3\"}]}]}", :routing_key => q.name)
    conn.close
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

  def create_soa_rr(record,type,obj)
    if type == 'bind'
      obj += "$TTL #{record.at}\n"
      obj += "#{dot(self.zone.downcase)} IN  SOA #{record.mname} #{record.rname} (\n"
      obj += " #{record.serial}\n"
      obj += " #{record.refresh}\n"
      obj += " #{record.retry}\n"
      obj += " #{record.expire}\n"
      obj += " #{record.at} )\n"
    else
      obj.SOA do |obj|
        obj.child! do |obj|
          obj.class   'in'
          obj.name    dot(self.zone.downcase)
          obj.mname   record.mname
          obj.rname   record.rname
          obj.at      record.at
          obj.serial  record.serial
          obj.refresh record.refresh
          obj.retry   record.retry
          obj.expire  record.expire
          obj.minimum record.minimum
        end
      end
    end

    obj
  end

  def create_ns_rr(records,type,obj,ns_name)
    records.each do |record|
      record.answers.each do |answer|
        if type == 'bind'
          obj += "#{record_name(ns_name)}  IN  NS  #{answer.data}\n"
        else
          obj.NS do |obj|
            records.each do |record|
              obj.child! do|obj|
                obj.class "in"
                obj.name record_name(ns_name)
                obj.ttl self.set_ttl(record)
                obj.value record.answers.each do |answer|
                  obj.weight 1
                  obj.ns answer.data
                end
              end
            end
          end
        end
      end
    end

    obj
  end

  def create_mx_details(obj,record,mx_name,answer,type)
    if type == 'bind'
      obj += "#{record_name(mx_name)}  IN  MX  #{answer.priority}  #{answer.data}\n"
    else
      obj.child! do|obj|
        obj.class "in"
        obj.ttl self.set_ttl(record)
        obj.name record_name(mx_name)
        obj.priority answer.priority
        obj.value answer.data
      end
    end

    obj
  end

  def create_mx_rr(records,type,obj,mx_name,routing_policy,region)
    if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
      records.each do |record|
        record = resolve_alias(record)
        unless record.nil?
          record.answers.each do |answer|
            obj = create_mx_details(obj,record,mx_name,answer,type)
          end
        end
      end
    elsif routing_policy == 'LATENCY'
      if records.where(:region => region).exists?
        records.where(:region => region).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            record.answers.each do |answer|
              obj = create_mx_details(obj,record,mx_name,answer,type)
            end
          end
        end
      else
        found = false
        region.neighbor_regions.order_by(:proximity => :asc).each do |n|
          unless found
            if records.where(:region => n.neighbor).exists?
              found = true
              records.where(:region => n.neighbor).each do |record|
                record = resolve_alias(record)
                unless record.nil?
                  record.answers.each do |answer|
                    obj = create_mx_details(obj,record,mx_name,answer,type)
                  end
                end
              end
            end
          end
        end
      end
    elsif routing_policy == 'FAILOVER'
      if records.where(:primary => true).exists?
        records.where(:primary => true).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            record.answers.each do |answer|
              obj = create_mx_details(obj,record,mx_name,answer,type)
            end
          end
        end
      else
        records.where(:primary => false).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            record.answers.each do |answer|
              obj = create_mx_details(obj,record,mx_name,answer,type)
            end
          end
        end
      end
    end
  end

  def create_cname_details(obj,record,cname_name,type,weighted_cname)
    if weighted_cname
      single = record.answers.count == 1
      answers = []

      record.answers.each do |answer|
        if type == 'bind'
          obj += "#{record_name(cname_name)}  IN  CNAME  #{answer.data}\n"
        else
          if single
            answers.push(weight: 1, cname: answer.data)
          else
            answers.push(weight: answer.weight, cname: answer.data)
          end
        end
      end

      unless type == 'bind'
        obj.child! do|obj|
          obj.class "in"
          obj.ttl self.set_ttl(record)
          obj.name record_name(cname_name)
          obj.value answers.each do |answer|
            obj.weight answer[:weight]
            obj.cname answer[:cname]
          end
        end
      end
    else
      answer = record.answers.first
      if type == 'bind'
        obj += "#{record_name(cname_name)}  IN  CNAME  #{answer.data}\n"
      else
        obj.child! do|obj|
          obj.class "in"
          obj.ttl self.set_ttl(record)
          obj.name record_name(cname_name)
          obj.value answer.data
        end
      end
    end
    obj
  end

  def create_cname_rr(records,type,obj,cname_name,routing_policy,region,weighted_cname)
    if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
      records.each do |record|
        record = resolve_alias(record)
        unless record.nil?
          obj = create_cname_details(obj,record,cname_name,type,weighted_cname)
        end
      end
    elsif routing_policy == 'LATENCY'
      if records.where(:region => region).exists?
        records.where(:region => region).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            obj = create_cname_details(obj,record,cname_name,type,weighted_cname)
          end
        end
      else
        found = false
        region.neighbor_regions.order_by(:proximity => :asc).each do |n|
          unless found
            if records.where(:region => n.neighbor).exists?
              found = true
              records.where(:region => n.neighbor).each do |record|
                record = resolve_alias(record)
                unless record.nil?
                  obj = create_cname_details(obj,record,cname_name,type,weighted_cname)
                end
              end
            end
          end
        end
      end
    elsif  routing_policy == 'FAILOVER'
      if records.where(:primary => true).exists?
        records.where(:primary => true).each do |record|
          record = resolve_alias(record)
          answer = record.answers.first
          unless record.nil?
            obj = create_cname_details(obj,record,cname_name,answer,type)
          end
        end
      else
        records.where(:primary => false).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            answer = record.answers.first
            obj = create_cname_details(obj,record,cname_name,answer,type)
          end
        end
      end
    end

    obj
  end

  def create_a_details(obj,record,a_name,type)
    answers = []
    single = record.answers.count == 1

    record.answers.each do |answer|
      if single
        answers.push(weight: 1, ip: answer.ip)
      else
        answers.push(weight: record.weight, ip: answer.ip)
      end
    end

    if type == 'bind'
      answers.each do |answer|
        obj += "#{record_name(a_name)}  IN  A  #{answer[:ip]}\n"
      end
    else
      obj.child! do|obj|
        obj.class "in"
        obj.name record_name(a_name)
        obj.ttl self.set_ttl(record)
        obj.value answers.each do |answer|
          obj.weight answer[:weight]
          obj.ip answer[:ip]
        end
      end
    end

    obj
  end

  def create_a_rr(records,type,obj,a_name,routing_policy,region)
    if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
      records.each do |record|
        record = resolve_alias(record)
        unless record.nil?
          obj = create_a_details(obj,record,a_name,type)
        end
      end
    elsif routing_policy == 'LATENCY'
      if records.where(:region => region).exists?
        records.where(:region => region).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            obj = create_a_details(obj,record,a_name,type)
          end
        end
      else
        found = false
        region.neighbor_regions.order_by(:proximity => :asc).each do |n|
          unless found
            if records.where(:region => n.neighbor).exists?
              found = true
              records.where(:region => n.neighbor).each do |record|
                record = resolve_alias(record)
                unless record.nil?
                  obj = create_a_details(obj,record,a_name,type)
                end
              end
            end
          end
        end
      end
    elsif  routing_policy == 'FAILOVER'
      if records.where(:primary => true).exists?
        records.where(:primary => true).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            obj = create_a_details(obj,record,a_name,type)
          end
        end
      else
        records.where(:primary => false).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            obj = create_a_details(obj,record,a_name,type)
          end
        end
      end
    end

    obj
  end


  def create_aaaa_details(obj,record,aaaa_name,type)
    answers = []
    single = record.answers.count == 1

    record.answers.each do |answer|
      if single
        answers.push(weight: 1, ip: answer.ip)
      else
        answers.push(weight: record.weight, ip: answer.ip)
      end
    end

    if type == 'bind'
      answers.each do |answer|
        obj += "#{record_name(aaaa_name)}  IN  AAAA  #{answer[:ip]}\n"
      end
    else
      obj.child! do|obj|
        obj.class "in"
        obj.name record_name(aaaa_name)
        obj.ttl self.set_ttl(record)
        obj.value answers.each do |answer|
          obj.weight answer[:weight]
          obj.ip answer[:ip]
        end
      end
    end

    obj
  end

  def create_aaaa_rr(records,type,obj,aaaa_name,routing_policy,region)
    if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
      records.each do |record|
        record = resolve_alias(record)
        unless record.nil?
          obj = create_aaaa_details(obj,record,aaaa_name,type)
        end
      end
    elsif routing_policy == 'LATENCY'
      if records.where(:region => region).exists?
        records.where(:region => region).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            obj = create_aaaa_details(obj,record,aaaa_name,type)
          end
        end
      else
        found = false
        region.neighbor_regions.order_by(:proximity => :asc).each do |n|
          unless found
            if records.where(:region => n.neighbor).exists?
              found = true
              records.where(:region => n.neighbor).each do |record|
                record = resolve_alias(record)
                unless record.nil?
                  obj = create_aaaa_details(obj,record,aaaa_name,type)
                end
              end
            end
          end
        end
      end
    elsif  routing_policy == 'FAILOVER'
      if records.where(:primary => true).exists?
        records.where(:primary => true).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            obj = create_aaaa_details(obj,record,aaaa_name,type)
          end
        end
      else
        records.where(:primary => false).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            obj = create_aaaa_details(obj,record,aaaa_name,type)
          end
        end
      end
    end

    obj
  end

  def create_srv_details(obj,record,srv_name,answer,type)
    if type == 'bind'
      obj += "#{record_name(srv_name)}  IN  SRV  #{answer.priority} #{answer.weight} #{answer.port}  #{answer.data}\n"
    else
      obj.child! do|obj|
        obj.class "in"
        obj.ttl self.set_ttl(record)
        obj.name record_name(srv_name)
        obj.priority answer.priority
        obj.weight answer.weight
        obj.port answer.port
        obj.target answer.data
      end
    end

    obj
  end

  def create_srv_rr(records,type,obj,srv_name,routing_policy,region)
    if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
      records.each do |record|
        record = resolve_alias(record)
        unless record.nil?
          record.answers.each do |answer|
            obj = create_srv_details(obj,record,srv_name,answer,type)
          end
        end
      end
    elsif routing_policy == 'LATENCY'
      if records.where(:region => region).exists?
        records.where(:region => region).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            record.answers.each do |answer|
              obj = create_srv_details(obj,record,srv_name,answer,type)
            end
          end
        end
      else
        found = false
        region.neighbor_regions.order_by(:proximity => :asc).each do |n|
          unless found
            if records.where(:region => n.neighbor).exists?
              found = true
              records.where(:region => n.neighbor).each do |record|
                record = resolve_alias(record)
                unless record.nil?
                  record.answers.each do |answer|
                    obj = create_srv_details(obj,record,srv_name,answer,type)
                  end
                end
              end
            end
          end
        end
      end
    elsif routing_policy == 'FAILOVER'
      if records.where(:primary => true).exists?
        records.where(:primary => true).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            record.answers.each do |answer|
              obj = create_srv_details(obj,record,srv_name,answer,type)
            end
          end
        end
      else
        records.where(:primary => false).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            record.answers.each do |answer|
              obj = create_srv_details(obj,record,srv_name,answer,type)
            end
          end
        end
      end
    end

    obj
  end

  def create_txt_details(obj,record,txt_name,answer,type)
    if type == 'bind'
      obj += "#{record_name(txt_name)}  IN  TXT  \"#{answer.priority} #{answer.weight} #{answer.port}  #{answer.data}\"\n"
    else
      obj.child! do|obj|
        obj.class "in"
        obj.ttl self.set_ttl(record)
        obj.name record_name(txt_name)
        obj.value do |obj|
          json.array! [answer.data]
        end
      end
    end

    obj
  end

  def create_txt_rr(records,type,obj,txt_name,routing_policy,region)
    if routing_policy == 'SIMPLE' or routing_policy == 'WEIGHTED'
      records.each do |record|
        record = resolve_alias(record)
        unless record.nil?
          record.answers.each do |answer|
            obj = create_txt_details(obj,record,txt_name,answer,type)
          end
        end
      end
    elsif routing_policy == 'LATENCY'
      if records.where(:region => region).exists?
        records.where(:region => region).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            record.answers.each do |answer|
              obj = create_txt_details(obj,record,txt_name,answer,type)
            end
          end
        end
      else
        found = false
        region.neighbor_regions.order_by(:proximity => :asc).each do |n|
          unless found
            if records.where(:region => n.neighbor).exists?
              found = true
              records.where(:region => n.neighbor).each do |record|
                record = resolve_alias(record)
                unless record.nil?
                  record.answers.each do |answer|
                    obj = create_txt_details(obj,record,txt_name,answer,type)
                  end
                end
              end
            end
          end
        end
      end
    elsif routing_policy == 'FAILOVER'
      if records.where(:primary => true).exists?
        records.where(:primary => true).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            record.answers.each do |answer|
              obj = create_txt_details(obj,record,txt_name,answer,type)
            end
          end
        end
      else
        records.where(:primary => false).each do |record|
          record = resolve_alias(record)
          unless record.nil?
            record.answers.each do |answer|
              obj = create_txt_details(obj,record,txt_name,answer,type)
            end
          end
        end
      end
    end

    obj
  end

  def create_ptr_rr(records,type,obj,ptr_name)
    records.each do |record|
      record.answers.each do |answer|
        if type == 'bind'
          obj += "#{record_name(ptr_name)}  IN  PTR  #{answer.data}\n"
        else
          obj.PTR do |obj|
            record = resolve_alias(record)
            unless record.nil?
              answer = record.answers.first
              obj.child! do|obj|
                obj.class "in"
                obj.ttl self.set_ttl(record)
                obj.name record_name(ptr_name)
                obj.value answer.data
              end
            end
          end
        end
      end
    end

    obj
  end

  def create_dnskey_rr(records,type,obj,dnskey_name)
    records.each do |record|
      if type == 'bind'
          record.answers.each do |answer|
          obj += "#{record_name(dnskey_name)}  IN  DNSKEY  #{answer.flags} #{answer.algorithm} #{answer.protocol} ( #{answer.publicKey} )\n"
        end
      else
        obj.DNSKEY do |obj|
          record = resolve_alias(record)
          unless record.nil?
            record.answers.each do |answer|
              obj.child! do|obj|
                obj.class "in"
                obj.ttl self.set_ttl(record)
                obj.name record_name(dnskey_name)
                obj.flags answer.flags
                obj.algorithm answer.protocol
                obj.protocol answer.algorithm
                obj.publicKey answer.publicKey
              end
            end
          end
        end
      end
    end

    obj
  end

  def create_rrsig_rr(records,type,obj,rrsig_name)
    records.each do |record|
      if type == 'bind'
        record.answers.each do |answer|
          obj += "#{record_name(rrsig_name)}  IN  RRSIG  #{answer.typeCovered} #{answer.algorithm} #{answer.labels} #{answer.originalTTL} #{answer.signatureExpiration} ( #{answer.signatureInception} #{answer.keyTag} #{answer.signerName} #{answer.signature} )\n"
        end
      else
        unless record.nil?
          obj.RRSIG do |obj|
            record.answers.each do |answer|
              obj.child! do|obj|
                obj.class "in"
                obj.ttl self.set_ttl(record)
                obj.name record_name(rrsig_name)
                obj.typeCovered answer.typeCovered
                obj.algorithm answer.algorithm
                obj.labels answer.labels
                obj.originalTTL answer.originalTTL
                obj.signatureExpiration answer.signatureExpiration
                obj.signatureInception answer.signatureInception
                obj.keyTag answer.keyTag
                obj.signerName answer.signerName
                obj.signature answer.signature
              end
            end
          end
        end
      end
    end

    obj
  end

  def bind_zone(region_id)
    if region_id.nil?
      region = nil
    else
      region = Region.find(region_id)
    end

    zone = ''
    # SOA
    return if self.records.where(:enabled => true, :operational => true, :trashed => false, :type => 'SOA').first.nil?

    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'SOA').exists?
      soa_record= self.records.where(:enabled => true, :operational => true, :trashed => false, :type => 'SOA').first.answers.first
      soa_record.update_serial
      zone = create_soa_rr(soa_record,'bind',zone)
    end

    # NS
    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'NS').exists?
      self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'NS').map(&:name).uniq.each do |ns_name|
        zone = create_ns_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'NS', :name => ns_name),'bind',zone,ns_name)
      end
    end

    ## MX
    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'MX').exists?
      self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'MX').map(&:name).uniq.each do |mx_name|
        routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'MX', :name => mx_name).first.routing_policy
        zone = create_mx_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'MX', :name => mx_name),'bind',zone,mx_name,routing_policy,region)
      end
    end

    ## CNAME
    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'CNAME').exists?
      self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'CNAME').map(&:name).uniq.each do |cname_name|
        routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'CNAME', :name => cname_name).first.routing_policy
        zone = create_cname_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'CNAME', :name => cname_name),'bind',zone,cname_name,routing_policy,region,Settings.weighted_cname.downcase == 'true')
      end
    end

    ## A
    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'A').exists?
      self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'A').map(&:name).uniq.each do |a_name|
        routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'A', :name => a_name).first.routing_policy
        zone = create_a_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'A', :name => a_name),'bind',zone,a_name,routing_policy,region)
      end
    end

    ## AAAA
    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'AAAA').exists?
      self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'AAAA').map(&:name).uniq.each do |aaaa_name|
        routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'AAAA', :name => aaaa_name).first.routing_policy
        zone = create_aaaa_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'AAAA', :name => aaaa_name),'bind',zone,aaaa_name,routing_policy,region)
      end
    end

    ## SRV
    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'SRV').exists?
      self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'SRV').map(&:name).uniq.each do |srv_name|
        routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'SRV', :name => srv_name).first.routing_policy
        zone = create_srv_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'SRV', :name => srv_name),'bind',zone,srv_name,routing_policy,region)
      end
    end

    ## TXT
    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'TXT').exists?
      self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'TXT').map(&:name).uniq.each do |txt_name|
        routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'TXT', :name => txt_name).first.routing_policy
        zone = create_txt_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'TXT', :name => txt_name),'bind',zone,txt_name,routing_policy,region)
      end
    end

    # PTR
    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'PTR').exists?
      self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'PTR').map(&:name).uniq.each do |ptr_name|
        zone = create_ptr_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'PTR', :name => ptr_name),'bind',zone,ptr_name)
      end
    end

    # DNSKEY
    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'DNSKEY').exists?
      self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'DNSKEY').map(&:name).uniq.each do |dnskey_name|
        zone = create_dnskey_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'DNSKEY', :name => dnskey_name),'bind',zone,dnskey_name)
      end
    end

    # RRSIG
    if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'RRSIG').exists?
      self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'RRSIG').map(&:name).uniq.each do |rrsig_name|
        zone = create_rrsig_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'RRSIG', :name => rrsig_name),'bind',zone,rrsig_name)
      end
    end

    zone
  end


  # Create the JSON of the zone:
  def json_zone(region_id)
    if region_id.nil?
      region = nil
    else
      region = Region.find(region_id)
    end


    return if self.records.where(:enabled => true, :operational => true, :trashed => false, :type => 'SOA').first.nil?
    soa_record= self.records.where(:enabled => true, :operational => true, :trashed => false, :type => 'SOA').first.answers.first
    soa_record.update_serial

    Jbuilder.encode do |json|
      json.origin dot(self.zone.downcase)
      json.ttl soa_record.at.to_i


      # SOA
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'SOA').exists?
        json = create_soa_rr(soa_record,'json',json)
      end


      # NS
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'NS').exists?
        self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'NS').map(&:name).uniq.each do |ns_name|
          json = create_ns_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'NS', :name => ns_name),'json',json,ns_name)
        end
      end

      ## MX
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'MX').exists?
        json.MX do |json|
          self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'MX').map(&:name).uniq.each do |mx_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'MX', :name => mx_name).first.routing_policy
            create_mx_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'MX', :name => mx_name),'json',json,mx_name,routing_policy,region)
          end
        end
      end

      ## CNAME
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'CNAME').exists?
        json.CNAME do |json|
          self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'CNAME').map(&:name).uniq.each do |cname_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :type => 'CNAME', :name => cname_name).first.routing_policy
            create_cname_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'CNAME', :name => cname_name),'json',json,cname_name,routing_policy,region,Settings.weighted_cname.downcase == 'true')
          end
        end
      end

      ## A
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'A').exists?
        json.A do |json|
          self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'A').map(&:name).uniq.each do |a_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'A', :name => a_name).first.routing_policy
            create_a_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'A', :name => a_name),'json',json,a_name,routing_policy,region)
          end
        end
      end

      ## AAAA
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'AAAA').exists?
        json.AAAA do |json|
          self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'AAAA').map(&:name).uniq.each do |aaaa_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'AAAA', :name => aaaa_name).first.routing_policy
            create_aaaa_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'AAAA', :name => aaaa_name),'json',json,aaaa_name,routing_policy,region)
          end
        end
      end

      ## SRV
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'SRV').exists?
        json.SRV do |json|
          self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'SRV').map(&:name).uniq.each do |srv_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'SRV', :name => srv_name).first.routing_policy
            create_srv_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'SRV', :name => srv_name),'json',json,srv_name,routing_policy,region)
          end
        end
      end

      ## TXT
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'TXT').exists?
        json.TXT do |json|
          self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'TXT').map(&:name).uniq.each do |txt_name|
            routing_policy = self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'TXT', :name => txt_name).first.routing_policy
            create_txt_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'TXT', :name => txt_name),'json',json,txt_name,routing_policy,region)
          end
        end
      end

      # PTR
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'PTR').exists?
        self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'PTR').map(&:name).uniq.each do |ptr_name|
          json = create_ptr_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'PTR', :name => ptr_name),'json',json,ptr_name)
        end
      end

      # DNSKEY
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'DNSKEY').exists?
        self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'DNSKEY').map(&:name).uniq.each do |dnskey_name|
          json = create_dnskey_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'DNSKEY', :name => dnskey_name),'json',json,dnskey_name)
        end
      end

      # RRSIG
      if self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'RRSIG').exists?
        self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'RRSIG').map(&:name).uniq.each do |rrsig_name|
          zone = create_rrsig_rr(self.records.where(:enabled => true, :operational => true, :trashed => false,  :type => 'RRSIG', :name => rrsig_name),'json',json,rrsig_name)
        end
      end

    end
  end
end
