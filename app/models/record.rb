class Record
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,           type: String
  field :type,           type: String
  field :ttl,            type: Integer, default: 60
  field :routing_policy, type: String, default: 'SIMPLE'
  field :set_id,         type: String
  field :weight,         type: Integer, default: 1
  field :primary,        type: Mongoid::Boolean, :default => true
  field :alias,          type: Mongoid::Boolean, :default => false
  field :enabled,        type: Mongoid::Boolean, :default => true
  field :operational,    type: Mongoid::Boolean, :default => true

  belongs_to :domain
  belongs_to :check
  belongs_to :region

  attr_accessor :geo_location

  embeds_many :answers

  accepts_nested_attributes_for :answers, allow_destroy: true, reject_if: :alias_allowed?

  before_validation :downcase_name, :check_weight_0

  before_save :set_region
  after_save  :update_dns
  after_destroy  :update_dns

  validates :name, :length => { maximum: 63 },
            :allow_blank => true,
            format: { :with => /\A([\-a-zA-Z0-9]+)\z/ }

  validate :unique_name?
  validate :check_answer_number

  validates :type, inclusion: { in: %w(A AAAA CNAME MX NS PTR SOA SRV TXT) }, :allow_nil => false, :allow_blank => false
  validates :routing_policy, inclusion: { in: %w(SIMPLE WEIGHTED LATENCY FAILOVER) }, :allow_nil => false, :allow_blank => false
  validates_presence_of :set_id, unless: Proc.new { |obj| obj.routing_policy == 'SIMPLE'}

  def check_weight_0
    self.weight = 1 if self.weight <= 0
  end

  def downcase_name
    self.name.downcase unless self.name.nil?
  end

  def unique_name?
    if self.type == 'SOA'
      errors.add(:name, 'SOA record can\'t have a name') unless self.name == '' or self.name == self.domain.zone
      errors.add(:name, 'Only one SOA record for domain') unless self.domain.records.where(:type => 'SOA').count == 0
    elsif self.type == 'CNAME'
      errors.add(:name, 'CNAME record conflicts with already present non-CNAME records') unless self.domain.records.where(:name => self.name).not_in(:type => 'CNAME').count == 0
      # Checks for routing_policy field
      # if already exists a CNAME record with the same name but with different routing policy
      errors.add(:routing_policy, 'Already have a resource with this name that conflicts with this routing policy (CNAME with other routing policy)') unless self.domain.records.where(:name => self.name, :type => 'CNAME').not_in(:routing_policy => self.routing_policy).count == 0
      # if already exists a CNAME record with the same name but with simple routing policy
      errors.add(:routing_policy, 'Already have a resource with this name that conflicts with this routing policy (CNAME with simple routing policy)') unless self.domain.records.where(:name => self.name, :type => 'CNAME', :routing_policy => 'SIMPLE').count == 0
      # if already exist a failover primary/secondary record and I request to be primary/secondary
      errors.add(:routing_policy, 'CNAME records doesn\'t works only with "weighted" routing policy') if self.routing_policy == 'WEIGHTED'
      if self.routing_policy == 'FAILOVER'
        if self.primary
          errors.add(:name, 'Already have a primary record with this name') unless self.domain.records.where(:name => self.name, :type => 'CNAME', :routing_policy => 'FAILOVER', :primary => true)
        else
          errors.add(:name, 'Already have a secondary record with this name') unless self.domain.records.where(:name => self.name, :type => 'CNAME', :routing_policy => 'FAILOVER', :primary => false)
        end
      end

    else
      errors.add(:name, 'This record conflicts with already present CNAME records') unless self.domain.records.where(:name => self.name, :type => 'CNAME').count == 0
      # Checks for routing_policy field
      # if already exists a non CNAME record with the same name but with different routing policy
      errors.add(:routing_policy, "Already have a resource with this name that conflicts with this routing policy (non CNAME with #{self.routing_policy} routing policy)") unless self.domain.records.where(:name => self.name, :type => self.type).not_in(:routing_policy => self.routing_policy).count == 0
      # if already exists a non CNAME record with the same name but with simple routing policy
      if self.type != 'NS' and self.type != 'MX' and self.routing_policy == 'SIMPLE'
#        errors.add(:routing_policy, 'Already have a resource with this name that conflicts with this routing policy (non CNAME with simple routing policy)') unless self.domain.records.where(:name => self.name, :type => self.type, :routing_policy => 'SIMPLE').first == self
      elsif self.type == 'NS'
        errors.add(:routing_policy, 'NS records works only with "simple" routing policy') unless self.routing_policy == 'SIMPLE'
      elsif self.type == 'PTR'
        errors.add(:routing_policy, 'PTR records works only with "simple" routing policy') unless self.routing_policy == 'SIMPLE'
      elsif self.type == 'MX'
        errors.add(:routing_policy, 'MX records doesn\'t works only with "weighted" routing policy') if self.routing_policy == 'WEIGHTED'
      elsif self.type == 'TXT'
        errors.add(:routing_policy, 'TXT records doesn\'t works only with "weighted" routing policy') if self.routing_policy == 'WEIGHTED'
      elsif self.type == 'SRV'
        errors.add(:routing_policy, 'SRV records doesn\'t works only with "weighted" routing policy') if self.routing_policy == 'WEIGHTED'
      end
      # if already exist a failover primary/secondary record and I request to be primary/secondary
      if self.routing_policy == 'FAILOVER'
        if self.primary
          errors.add(:name, 'Already have a primary record with this name') unless self.domain.records.where(:name => self.name, :type => self.type, :routing_policy => 'FAILOVER', :primary => true)
        else
          errors.add(:name, 'Already have a secondary record with this name') unless self.domain.records.where(:name => self.name, :type => self.type, :routing_policy => 'FAILOVER', :primary => false)
        end
      end
    end
  end

  def check_alias_recursor(record,type)
    logger.debug("Record name: #{record}")
    zone = Domain.new.zone_name(record)
    last_level = Domain.new.record_last_level(record)
    logger.debug("ZOne: #{zone}, Last Level: #{last_level}, Type = #{type}")

    a = Domain.where(zone: zone).first.records.where(name: last_level).first
    logger.debug("#{a.type} == #{type}")

    if a.type == type
      logger.debug "Return True"
      return true
    else
      logger.debug "Return Fasle"
      return false
    end
  end

  def answers_count_valid?
    answers.reject(&:marked_for_destruction?).count >= 1
  end

  def check_answer_number
    unless answers_count_valid?
      errors.add(:answers, 'no valid answers found')
    end
  end

  def alias_allowed?(attributes)
    if self.alias
      if (self.type == 'NS' or self.type == 'SOA')
        errors.add(:alias, 'alias are not allowed for this type of record') if self.name != '' or self.name != self.domain.zone
      else
        logger.debug attributes
        errors.add(:alias,'alias destination must be of the same type') unless check_alias_recursor(attributes[:data],self.type)
      end
    end
  end

  def set_region
    if self.routing_policy == 'LATENCY'
      unless self.geo_location.nil?
        self.region = Region.find(self.geo_location)
      end
    end
  end

  def update_dns
    self.domain.send_to_rabbit(:update)
  end
end
