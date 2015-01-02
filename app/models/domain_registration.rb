class DomainRegistration
  require "lib/regdom/dummy"
  require "lib/regdom/email"
  require "lib/regdom/resellerclub"
  require "lib/regdom/enom"

  include Mongoid::Document
  include Mongoid::Timestamps

  field :domain,                  type: String, default: "domain"
  field :tld,                     type: String, default: "it"
  field :ns1,                     type: String, default: Settings.ns01.chomp('.')
  field :ns2,                     type: String, default: Settings.ns02.chomp('.')
  field :ns3,                     type: String, default: Settings.ns03.chomp('.')
  field :ns4,                     type: String, default: Settings.ns04.chomp('.')
  field :ns5,                     type: String, default: Settings.ns05.chomp('.')
  field :reseller_service,        type: String, default: "ResellerClub"
  field :order_id,                type: String, default: "saiis3298c"
  field :registration_date,       type: DateTime
  field :expire_date,             type: String

  field :registrant_contact_code, type: String
  field :tech_contact_code,       type: String
  field :admin_contact_code,      type: String

  attr_accessor :auth_code

  belongs_to :user

  belongs_to :registrant_contact, class_name: "Contact", inverse_of: :domain_registration_registrant_contact
  belongs_to :tech_contact,       class_name: "Contact", inverse_of: :domain_registration_tech_contact
  belongs_to :admin_contact,      class_name: "Contact", inverse_of: :domain_registration_admin_contact

  has_many :child_dns


  before_create :create_domain_callback
  before_update :update_domain_callback
  before_destroy :destroy_domain_callback

  def create_domain_callback
    m = eval "Settings.domain_registers_#{self.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.reseller_service = m
    if regdom.pre_register_contact?
      self.registrant_contact_code = regdom.create_contact(self.registrant_contact,self)
      self.tech_contact_code = regdom.create_contact(self.tech_contact,self)
      self.admin_contact_code = regdom.create_contact(self.admin_contact,self)
    end

    if self.registrant_contact_code.include?('ERROR') or self.tech_contact_code.include?('ERROR') or self.admin_contact_code.include?('ERROR')
      false
    else
      response = regdom.register_domain(self)
      if response.to_s.include?('error')
        false
      else
        self.order_id = response["entityid"]
        self.set_expire_date
        response
      end
    end
  end

  def update_domain_callback
    m = eval "Settings.domain_registers_#{self.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.reseller_service = m
    response = regdom.update_domain(self)
    if response.to_s.include?('error')
      false
    else
      response
    end
  end

  def destroy_domain_callback
    m = eval "Settings.domain_registers_#{self.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.reseller_service = m
    response = regdom.destroy_domain(self)
    if response.to_s.include?('error')
      false
    else
      response
    end
  end

  def transfer
    m = eval "Settings.domain_registers_#{self.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.reseller_service = m

    if regdom.pre_register_contact?
      self.registrant_contact_code = regdom.create_contact(self.registrant_contact,self)
      self.tech_contact_code = regdom.create_contact(self.tech_contact,self)
      self.admin_contact_code = regdom.create_contact(self.admin_contact,self)
    end

    if self.registrant_contact_code.include?('ERROR') or self.tech_contact_code.include?('ERROR') or self.admin_contact_code.include?('ERROR')
      false
    else
      response = regdom.transfer_domain(self)
      if response.to_s.include?('error')
        false
      else
        self.order_id = response["entityid"]
        self.set_expire_date
        response
      end
    end

  end

  def renew
    m = eval "Settings.domain_registers_#{self.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.reseller_service = m
    response = regdom.renew_domain(self)
    if response.to_s.include?('error')
      false
    else
      self.set_expire_date
      response
    end
  end

  def lock
    m = eval "Settings.domain_registers_#{self.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.reseller_service = m
    response = regdom.lock_domain(self)
    if response.to_s.include?('error')
      false
    else
      response
    end
  end

  def unlock
    m = eval "Settings.domain_registers_#{self.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.reseller_service = m
    response = regdom.unlock_domain(self)
    if response.to_s.include?('error')
      false
    else
      response
    end
  end

  def epp_key
    m = eval "Settings.domain_registers_#{self.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.reseller_service = m
    response = regdom.epp_key_domain(self)
    if response.to_s.include?('error')
      false
    else
      response
    end
  end

  def set_expire_date
    m = eval "Settings.domain_registers_#{self.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.reseller_service = m
    response = regdom.expire_date(self)
    if response.to_s.include?('error')
      false
    else
      self.set(expire_date: response)
    end
  end
end
